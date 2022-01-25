# typed: strong
module FQL
  VERSION = "0.1.0".freeze

  module Serde
    class JSON
      extend T::Sig
      extend T::Generic

      sig { params(input: String).returns(Query::DSL::BoolExpr) }
      def deserialize(input); end

      sig { params(expr: Query::DSL::BoolExpr).returns(String) }
      def serialize(expr); end

      sig { params(expr: T.nilable(T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr))).returns(T.any(
            T::Hash[Symbol, T.untyped],
            T::Boolean,
            String,
            Integer,
            Date,
            NilClass
          )) }
      def serialize_expression(expr); end

      sig { params(expr: T.any(T::Hash[String, T.untyped], T::Boolean, Integer, String,
                           Date, NilClass)).returns(T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr, NilClass)) }
      def parse_expression(expr); end
    end
  end

  class Validation
    extend T::Sig

    class Result < T::Struct
      prop :errors, T::Array[String], immutable: true

      extend T::Sig

      sig { returns(T::Boolean) }
      def valid?; end
    end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::BoolExpr).returns(Result) }
    def self.validate(model, expr); end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::BoolExpr).void }
    def initialize(model, expr); end

    sig { returns(Result) }
    def validate; end

    sig { params(expr: T.nilable(T.any(Query::DSL::BoolExpr,
                                   Query::DSL::ValueExpr))).returns(T.nilable(T.class_of(ActiveRecord::Base))) }
    def validate_expression!(expr); end

    sig { returns(T.class_of(ActiveRecord::Base)) }
    attr_reader :model

    sig { returns(Query::DSL::BoolExpr) }
    attr_reader :expr

    sig { returns(T::Array[String]) }
    attr_reader :errors
  end

  module Backend
    class Arel
      extend T::Sig
      extend T::Generic
      PlainValue = T.type_alias { T.any(String, Integer, Date, NilClass) }
      Attribute = T.type_alias { T.any(::Arel::Attribute, A::True, A::False) }
      Table = T.type_alias { T.any(::Arel::Table, A::TableAlias) }
      A = ::Arel::Nodes

      sig { params(model: T.class_of(ActiveRecord::Base), vars: T::Hash[Symbol, T.untyped]).void }
      def initialize(model, vars = {}); end

      sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::BoolExpr, vars: T::Hash[Symbol, T.untyped]).returns(ActiveRecord::Relation) }
      def self.compile(model, expr, vars = {}); end

      sig { params(expr: Query::DSL::BoolExpr).returns(ActiveRecord::Relation) }
      def compile(expr); end

      sig { params(expr: T.any(Query::DSL::BoolExpr,
                           Query::DSL::ValueExpr, NilClass)).returns(T.any(A::Node, PlainValue, Table, Attribute)) }
      def compile_expression(expr); end

      sig { returns(T.class_of(ActiveRecord::Base)) }
      attr_reader :model

      sig { returns(::Arel::Table) }
      attr_reader :arel_table

      sig { returns(T::Array[T.untyped]) }
      attr_reader :joins

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :vars
    end

    module Ruby
      extend T::Sig
      CompiledFunction = T.type_alias { T.proc.params(
          arg0: T.untyped, # __itself__
          arg1: T::Hash[Symbol, T.untyped] # __fql_vars__
        ).returns(T::Boolean) }

      sig { params(expr: Query::DSL::BoolExpr).returns(CompiledFunction) }
      def self.compile(expr); end

      sig { params(expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr, NilClass)).returns(String) }
      def self.compile_expression(expr); end
    end
  end

  class Query
    extend T::Sig

    sig { params(expr: DSL::BoolExpr).void }
    def initialize(expr); end

    sig { params(input: String).returns(T.attached_class) }
    def self.from_json(input); end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby; end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(ActiveRecord::Relation) }
    def to_arel(model); end

    sig { returns(String) }
    def to_json; end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(Validation::Result) }
    def validate(model); end

    sig { returns(DSL::BoolExpr) }
    attr_reader :expr

    module DSL
      extend T::Sig
      extend Methods
      BoolExpr = T.type_alias { T.any(Or, And, Eq, Gt, Gte, Lt, Lte, Not, Contains, MatchesRegex, T::Boolean) }
      Primitive = T.type_alias { T.any(String, Integer, Date, T::Boolean) }
      ValueExpr = T.type_alias { T.any(Attr, Rel, Var, Primitive) }

      class And < T::Struct
        prop :lhs, T.untyped, immutable: true
        prop :rhs, T.untyped, immutable: true

      end

      class Or < T::Struct
        prop :lhs, T.untyped, immutable: true
        prop :rhs, T.untyped, immutable: true

      end

      class Not < T::Struct
        prop :expr, T.untyped, immutable: true

      end

      class Rel < T::Struct
        prop :name, T::Array[Symbol], immutable: true

      end

      class Attr < T::Struct
        prop :target, Rel, immutable: true
        prop :name, Symbol, immutable: true

      end

      class Var < T::Struct
        prop :name, Symbol, immutable: true

      end

      class Eq < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, T.any(ValueExpr, NilClass), immutable: true

      end

      class Gt < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

      end

      class Lt < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

      end

      class Gte < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

      end

      class Lte < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

      end

      class Contains < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, String, immutable: true

      end

      class MatchesRegex < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, String, immutable: true

      end

      module Methods
        extend T::Sig

        sig { params(lhs: BoolExpr, rhs: BoolExpr).returns(And) }
        def and(lhs, rhs); end

        sig { params(lhs: BoolExpr, rhs: BoolExpr).returns(Or) }
        def or(lhs, rhs); end

        sig { params(expr: BoolExpr).returns(Not) }
        def not(expr); end

        sig { params(name: T.any(Symbol, T::Array[Symbol])).returns(Rel) }
        def rel(name); end

        sig { params(target: Rel, name: Symbol).returns(Attr) }
        def attr(target, name); end

        sig { params(name: Symbol).returns(Var) }
        def var(name); end

        sig { params(lhs: ValueExpr, rhs: T.any(ValueExpr, NilClass)).returns(Eq) }
        def eq(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Gt) }
        def gt(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Gte) }
        def gte(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Lt) }
        def lt(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: ValueExpr).returns(Lte) }
        def lte(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: String).returns(Contains) }
        def contains(lhs, rhs); end

        sig { params(lhs: ValueExpr, rhs: String).returns(MatchesRegex) }
        def matches_regex(lhs, rhs); end
      end

      sig { params(base: Module).void }
      def self.included(base); end
    end
  end
end
