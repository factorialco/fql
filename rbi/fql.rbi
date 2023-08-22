# typed: strong
module FQL
  VERSION = "0.2.12".freeze

  class Library
    extend T::Sig

    sig { params(name: Symbol, body: T.proc.params(args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr)).void }
    def self.function(name, &body); end

    sig { returns(T::Hash[Symbol, T.proc.params(args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr)]) }
    def self.functions; end

    sig { returns(Library) }
    def self.empty; end

    sig { params(name: Symbol, args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr) }
    def call(name, args); end

    sig { returns(String) }
    def inspect; end
  end

  class Outcome
    extend T::Sig
    extend T::Generic
    Elem = type_member

    sig { type_parameters(:T).params(value: T.type_parameter(:T)).returns(Outcome[T.type_parameter(:T)]) }
    def self.ok(value); end

    sig { params(message: String, exception: T.nilable(StandardError)).returns(Outcome[T.untyped]) }
    def self.error(message, exception = nil); end

    sig { params(obj: T.any(Ok[Elem], Error)).void }
    def initialize(obj); end

    sig { returns(T::Boolean) }
    def ok?; end

    sig { returns(T::Boolean) }
    def error?; end

    sig { returns(T.nilable(Error)) }
    def error; end

    sig { returns(T.nilable(Elem)) }
    def value; end

    sig { returns(Elem) }
    def unwrap!; end

    sig { type_parameters(:U).params(_block: T.proc.params(arg0: Elem).returns(T.type_parameter(:U))).returns(Outcome[T.type_parameter(:U)]) }
    def map(&_block); end

    sig { type_parameters(:U).params(_block: T.proc.params(arg0: Elem).returns(Outcome[T.untyped])).returns(Outcome[T.untyped]) }
    def bind(&_block); end

    class Ok < T::Struct
      prop :value, Elem, immutable: true

      extend T::Sig
      extend T::Generic
      Elem = type_member
    end

    class Error < T::Struct
      prop :message, String, immutable: true
      prop :exception, T.nilable(StandardError), immutable: true

      extend T::Sig
    end
  end

  module Serde
    class JSON
      extend T::Sig
      extend T::Generic

      sig { params(input: T::Hash[T.any(String, Symbol), T.untyped]).returns(Outcome[Query::DSL::Root]) }
      def deserialize(input); end

      sig { params(expr: Query::DSL::Root).returns(T::Hash[Symbol, T.untyped]) }
      def serialize(expr); end

      sig { params(expr: T.nilable(Query::DSL::Expr)).returns(T.any(
            T::Hash[Symbol, T.untyped],
            T::Array[T.untyped],
            T::Boolean,
            String,
            Integer,
            Date,
            NilClass
          )) }
      def serialize_expression(expr); end

      sig { params(expr: T.any(T::Hash[Symbol, T.untyped], T::Boolean, Integer, String,
                           Date, NilClass, T::Array[T.untyped])).returns(Outcome[T.any(Query::DSL::Expr, NilClass)]) }
      def parse_expression(expr); end
    end
  end

  class Validation
    extend T::Sig
    extend T::Generic

    class Result < T::Struct
      prop :errors, T::Array[String], immutable: true

      extend T::Sig

      sig { returns(T::Boolean) }
      def valid?; end
    end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::Root, library: Library).returns(Result) }
    def self.validate(model, expr, library: Library.empty); end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::Root, library: Library).void }
    def initialize(model, expr, library: Library.empty); end

    sig { returns(Result) }
    def validate; end

    sig { params(expr: T.nilable(Query::DSL::Expr)).returns(T.nilable(T.class_of(ActiveRecord::Base))) }
    def validate_expression!(expr); end

    sig { returns(T.class_of(ActiveRecord::Base)) }
    attr_reader :model

    sig { returns(Query::DSL::Root) }
    attr_reader :expr

    sig { returns(T::Array[String]) }
    attr_reader :errors

    sig { returns(Library) }
    attr_reader :library
  end

  module Backend
    class Arel
      extend T::Sig
      PlainValue = T.type_alias { T.any(String, Integer, Date, NilClass, T::Array[Query::DSL::Primitive]) }
      Attribute = T.type_alias { T.any(::Arel::Attribute, A::True, A::False) }
      Table = T.type_alias { T.any(::Arel::Table, A::TableAlias) }
      A = ::Arel::Nodes

      sig { params(model: T.class_of(ActiveRecord::Base), vars: T::Hash[Symbol, T.untyped], library: Library).void }
      def initialize(model, vars: {}, library: Library.empty); end

      sig do
        params(
          model: T.class_of(ActiveRecord::Base),
          expr: Query::DSL::Root,
          vars: T::Hash[Symbol, T.untyped],
          library: Library
        ).returns(ActiveRecord::Relation)
      end
      def self.compile(model, expr, vars: {}, library: Library.empty); end

      sig { params(expr: Query::DSL::Root).returns(ActiveRecord::Relation) }
      def compile(expr); end

      sig { params(expr: T.any(Query::DSL::Expr, NilClass, T::Array[Query::DSL::Primitive])).returns(T.any(A::Node, PlainValue, Table, Attribute)) }
      def compile_expression(expr); end

      sig { returns(T.class_of(ActiveRecord::Base)) }
      attr_reader :model

      sig { returns(::Arel::Table) }
      attr_reader :arel_table

      sig { returns(T::Array[T.untyped]) }
      attr_reader :joins

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :vars

      sig { returns(Library) }
      attr_reader :library
    end

    module Ruby
      extend T::Sig
      CompiledFunction = T.type_alias { T.proc.params(
          arg0: T.untyped, # __itself__
          arg1: T::Hash[Symbol, T.untyped] # __fql_vars__
        ).returns(T::Boolean) }

      sig { params(expr: Query::DSL::Root, library: Library).returns(CompiledFunction) }
      def self.compile(expr, library:); end

      sig { params(expr: T.any(Query::DSL::Expr, NilClass, T::Array[Query::DSL::Primitive]), lib: Library).returns(String) }
      def self.compile_expression(expr, lib); end
    end

    class Words
      extend T::Sig

      sig { params(expr: Query::DSL::Root, suffix: T.nilable(String), library: Library).returns(String) }
      def self.compile(expr, suffix: nil, library: Library.empty); end

      sig do
        params(
          expr: T.any(Query::DSL::Root, Query::DSL::ValueExpr),
          negated: T::Boolean,
          suffix: T.nilable(String),
          library: Library
        ).returns(String)
      end
      def self.compile_expression(expr, negated: false, suffix: nil, library: Library.empty); end

      sig { params(suffix: T.nilable(String), key: String, kwargs: String).returns(String) }
      def self.t(suffix, key, **kwargs); end
    end
  end

  class Query
    extend T::Sig

    sig { params(expr: DSL::Root, library: Library).void }
    def initialize(expr, library: Library.empty); end

    sig { params(input: T::Hash[T.any(String, Symbol), T.untyped], library: Library).returns(Outcome[T.attached_class]) }
    def self.from_json(input, library: Library.empty); end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby; end

    sig { params(model: T.class_of(ActiveRecord::Base), vars: T::Hash[Symbol, T.untyped]).returns(ActiveRecord::Relation) }
    def to_arel(model, vars = {}); end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_json; end

    sig { params(suffix: T.nilable(String)).returns(String) }
    def to_words(suffix: nil); end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(Validation::Result) }
    def validate(model); end

    sig { params(another_expr: DSL::Root).returns(Query) }
    def and(another_expr); end

    sig { params(another_expr: DSL::Root).returns(Query) }
    def or(another_expr); end

    sig { returns(Query) }
    def not; end

    sig { returns(DSL::Root) }
    attr_reader :expr

    sig { returns(Library) }
    attr_reader :library

    module DSL
      extend T::Sig
      extend Methods
      BoolExpr = T.type_alias { T.any(Or, And, Eq, Gt, Gte, Lt, Lte, Not, OneOf, Contains, MatchesRegex, T::Boolean) }
      Primitive = T.type_alias { T.any(String, Integer, Date, T::Boolean) }
      ValueExpr = T.type_alias { T.any(Attr, Rel, Var, Call, Primitive, T::Array[Primitive]) }
      Expr = T.type_alias { T.any(BoolExpr, ValueExpr) }
      Root = T.type_alias { T.any(BoolExpr, Call) }

      module Node
        extend T::Sig

        sig { params(base: Module).void }
        def self.included(base); end
      end

      class And < T::Struct
        prop :lhs, T.untyped, immutable: true
        prop :rhs, T.untyped, immutable: true

        include Node
      end

      class Or < T::Struct
        prop :lhs, T.untyped, immutable: true
        prop :rhs, T.untyped, immutable: true

        include Node
      end

      class Not < T::Struct
        prop :expr, T.untyped, immutable: true

        include Node
      end

      class Rel < T::Struct
        prop :name, T::Array[Symbol], immutable: true

        include Node
      end

      class Attr < T::Struct
        prop :target, Rel, immutable: true
        prop :name, Symbol, immutable: true

        include Node
      end

      class Var < T::Struct
        prop :name, Symbol, immutable: true

        include Node
      end

      class Call < T::Struct
        prop :name, Symbol, immutable: true
        prop :arguments, T::Array[T.untyped], immutable: true

        include Node
      end

      class Eq < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, T.any(ValueExpr, NilClass), immutable: true

        include Node
      end

      class Gt < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

        include Node
      end

      class Lt < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

        include Node
      end

      class Gte < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

        include Node
      end

      class Lte < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, ValueExpr, immutable: true

        include Node
      end

      class OneOf < T::Struct
        prop :member, ValueExpr, immutable: true
        prop :set, T::Array[Primitive], immutable: true

        include Node
      end

      class Contains < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, String, immutable: true

        include Node
      end

      class MatchesRegex < T::Struct
        prop :lhs, ValueExpr, immutable: true
        prop :rhs, String, immutable: true

        include Node
      end

      module Methods
        extend T::Sig

        sig { type_parameters(:T).params(metadata: T::Hash[Symbol, T.untyped], node: T.all(T.type_parameter(:T), Node)).returns(T.type_parameter(:T)) }
        def with_meta(metadata, node); end

        sig { params(lhs: Root, rhs: Root).returns(And) }
        def and(lhs, rhs); end

        sig { params(lhs: Expr, rhs: Expr).returns(Or) }
        def or(lhs, rhs); end

        sig { params(expr: Root).returns(Not) }
        def not(expr); end

        sig { params(name: T.any(Symbol, T::Array[Symbol])).returns(Rel) }
        def rel(name); end

        sig { params(target: Rel, name: Symbol).returns(Attr) }
        def attr(target, name); end

        sig { params(name: Symbol).returns(Var) }
        def var(name); end

        sig { params(name: Symbol, args: T.any(ValueExpr, NilClass)).returns(Call) }
        def call(name, *args); end

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

        sig { params(member: ValueExpr, set: T::Array[Primitive]).returns(OneOf) }
        def one_of(member, set); end

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
