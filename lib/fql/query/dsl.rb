# typed: strict
require "date"
require "sorbet-struct-comparable"

module FQL
  class Query
    module DSL
      extend T::Sig

      module Node
        extend T::Sig

        sig { params(base: Module).void }
        def self.included(base)
          base.include T::Struct::ActsAsComparable
          base.const :metadata, T::Hash[Symbol, T.untyped], default: {}
        end
      end

      class And < T::Struct
        include Node

        const :lhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
        const :rhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      class Or < T::Struct
        include Node

        const :lhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
        const :rhs, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      class Not < T::Struct
        include Node

        const :expr, T.untyped # BoolExpr, but Sorbet can't do recursive type aliases
      end

      # Resolve a relation.
      # The special relation named `:self` resolves to the root entity.
      class Rel < T::Struct
        include Node

        const :name, T::Array[Symbol]
      end

      # Resolve an attribute of a relation.
      class Attr < T::Struct
        include Node

        const :target, Rel
        const :name, Symbol
      end

      # Resolve a variable at runtime that will be passed to the interpreter.
      class Var < T::Struct
        include Node

        const :name, Symbol
      end

      # Resolve a variable at runtime that will be passed to the interpreter.
      class Call < T::Struct
        include Node

        const :name, Symbol
        const :arguments, T::Array[T.untyped]
      end

      BoolExpr = T.type_alias { T.any(Or, And, Eq, Gt, Gte, Lt, Lte, Not, OneOf, Contains, MatchesRegex, T::Boolean) }
      Primitive = T.type_alias { T.any(String, Integer, Date, T::Boolean) }
      ValueExpr = T.type_alias { T.any(Attr, Rel, Var, Call, Primitive, T::Array[Primitive]) }

      Expr = T.type_alias { T.any(BoolExpr, ValueExpr) }

      Root = T.type_alias { T.any(BoolExpr, Call) }

      # Determine equality between two values.
      class Eq < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, T.any(ValueExpr, NilClass)
      end

      class Gt < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Lt < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Gte < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class Lte < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, ValueExpr
      end

      class OneOf < T::Struct
        include Node

        const :member, ValueExpr
        const :set, T::Array[Primitive]
      end

      class Contains < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, String
      end

      class MatchesRegex < T::Struct
        include Node

        const :lhs, ValueExpr
        const :rhs, String
      end

      module Methods
        extend T::Sig

        sig do
          type_parameters(:T)
            .params(
              metadata: T::Hash[Symbol, T.untyped],
              node: T.all(T.type_parameter(:T), Node)
            )
            .returns(T.type_parameter(:T))
        end
        def with_meta(metadata, node)
          node.tap { |n| n.metadata.merge!(metadata) }
        end

        sig { params(lhs: Root, rhs: Root).returns(And) }
        def and(lhs, rhs)
          And.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: Expr, rhs: Expr).returns(Or) }
        def or(lhs, rhs)
          Or.new(lhs: lhs, rhs: rhs)
        end

        sig { params(expr: Root).returns(Not) }
        def not(expr)
          Not.new(expr: expr)
        end

        sig { params(name: T.any(Symbol, T::Array[Symbol])).returns(Rel) }
        def rel(name)
          if name.is_a?(Symbol)
            Rel.new(name: [name])
          else
            Rel.new(name: name)
          end
        end

        sig { params(target: Rel, name: Symbol).returns(Attr) }
        def attr(target, name)
          Attr.new(target: target, name: name)
        end

        sig { params(name: Symbol).returns(Var) }
        def var(name)
          Var.new(name: name)
        end

        sig { params(name: Symbol, args: T.any(ValueExpr, NilClass)).returns(Call) }
        def call(name, *args)
          Call.new(name: name, arguments: args)
        end

        sig { params(lhs: ValueExpr, rhs: T.any(ValueExpr, NilClass)).returns(Eq) }
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

        sig { params(member: ValueExpr, set: T::Array[Primitive]).returns(OneOf) }
        def one_of(member, set)
          OneOf.new(member: member, set: set)
        end

        sig { params(lhs: ValueExpr, rhs: String).returns(Contains) }
        def contains(lhs, rhs)
          Contains.new(lhs: lhs, rhs: rhs)
        end

        sig { params(lhs: ValueExpr, rhs: String).returns(MatchesRegex) }
        def matches_regex(lhs, rhs)
          MatchesRegex.new(lhs: lhs, rhs: rhs)
        end
      end

      sig { params(base: Module).void }
      def self.included(base)
        base.include(Methods)
      end

      extend Methods
    end
  end
end
