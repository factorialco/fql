# typed: strict
require 'date'

module FQL
  class Query
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

    BoolExpr = T.type_alias { T.any(Or, And, Eq, Gt, Gte, Lt, Lte, Not, T::Boolean) }
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

    sig { params(expr: BoolExpr).void }
    def initialize(expr)
      @expr = expr
    end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby
      Backend::Ruby.compile(expr)
    end

    private

    sig { returns(BoolExpr) }
    attr_reader :expr
  end
end
