# typed: ignore
require 'date'

module FQL
  class Query
    module DSL
      extend T::Sig

      class And < T::Struct
        const :lhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
        const :rhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      class Or < T::Struct
        const :lhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
        const :rhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      class Not < T::Struct
        const :expr, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      # Resolve a relation.
      # The special relation named `:self` resolves to the root entity.
      class Rel < T::Struct
        const :name, Symbol
      end

      # Resolve an attribute of a relation.
      class Attr < T::Struct
        const :target, Rel
        const :name, Symbol
      end

      # Resolve a variable at runtime that will be passed to the interpreter.
      class Var < T::Struct
        const :name, Symbol
      end

      BoolExpr = T.type_alias { T.any(Or, And, Eq, Gt, Gte, Lt, Lte, Not, Contains, T::Boolean) }
      Primitive = T.type_alias { T.any(String, Integer, Date, T::Boolean) }
      ValueExpr = T.type_alias { T.any(Attr, Rel, Var, Primitive) }

      # Determine equality between two values.
      class Eq < T::Struct
        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Gt < T::Struct
        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Lt < T::Struct
        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Gte < T::Struct
        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Lte < T::Struct
        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Contains < T::Struct
        const :lhs, ValueExpr
        const :rhs, String
      end

      module Methods
        extend T::Sig

        sig { params(lhs: BoolExpr, rhs: BoolExpr).returns(And) }
        def and(lhs, rhs)
          And.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: BoolExpr, rhs: BoolExpr).returns(Or) }
        def or(lhs, rhs)
          Or.new(lhs: lhs, rhs: rhs)
        end

        sig { params(expr: BoolExpr).returns(Not) }
        def not(expr)
          Not.new(expr: expr)
        end

        sig { params(name: Symbol).returns(Rel) }
        def rel(name)
          Rel.new(name: name)
        end

        sig { params(target: Rel, name: Symbol).returns(Attr) }
        def attr(target, name)
          Attr.new(target: target, name: name)
        end

        sig { params(name: Symbol).returns(Var) }
        def var(name)
          Var.new(name: name)
        end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Eq) }
        def eq(lhs, rhs)
          Eq.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Gt) }
        def gt(lhs, rhs)
          Gt.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Gte) }
        def gte(lhs, rhs)
          Gte.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Lt) }
        def lt(lhs, rhs)
          Lt.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Lte) }
        def lte(lhs, rhs)
          Lte.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: String).returns(Contains) }
        def contains(lhs, rhs)
          Contains.new(lhs: lhs, rhs: rhs)
        end
      end

      sig { params(base: Module).void }
      def self.included(base)
        base.include(Methods)
      end

      sig { params(base: Module).void }
      def self.extended(base)
        base.extend(Methods)
      end
    end
  end
end
