# typed: strict
require "active_record"
require "sorbet-rails"

module FQL
  class Query
    extend T::Sig

    sig { params(expr: DSL::Expr, library: Library).void }
    def initialize(expr, library: Library.empty)
      @expr = expr
      @library = library
    end

    sig { params(input: T::Hash[T.any(String, Symbol), T.untyped]).returns(Outcome[T.attached_class]) }
    def self.from_json(input)
      Serde::JSON.new.deserialize(input).map do |parsed|
        new(parsed)
      end
    end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby
      Backend::Ruby.compile(expr, library: library)
    end

    sig do
      params(
        model: T.class_of(ActiveRecord::Base),
        vars: T::Hash[Symbol, T.untyped]
      ).returns(ActiveRecord::Relation)
    end
    def to_arel(model, vars={})
      Backend::Arel.compile(model, expr, vars: vars, library: library)
    end

    sig { returns(T::Hash[Symbol, T.untyped]) }
    def to_json
      Serde::JSON.new.serialize(expr)
    end

    sig { params(suffix: T.nilable(String)).returns(String) }
    def to_words(suffix: nil)
      Backend::Words.compile(expr, suffix: suffix, library: library)
    end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(Validation::Result) }
    def validate(model)
      Validation.validate(model, expr, library: library)
    end

    sig { params(another_expr: DSL::Root).returns(Query) }
    def and(another_expr)
      self.class.new(DSL::And.new(lhs: expr, rhs: another_expr))
    end

    sig { params(another_expr: DSL::Expr).returns(Query) }
    def or(another_expr)
      self.class.new(DSL::Or.new(lhs: expr, rhs: another_expr))
    end

    sig { returns(Query) }
    def not
      self.class.new(DSL::Not.new(expr: expr))
    end

    sig { returns(DSL::Expr) }
    attr_reader :expr

    private

    sig { returns(Library) }
    attr_reader :library
  end
end
