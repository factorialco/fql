# typed: strict
require "active_record"
require "sorbet-rails"

module FQL
  class Query
    extend T::Sig

    sig { params(expr: DSL::BoolExpr).void }
    def initialize(expr)
      @expr = expr
    end

    sig { params(input: String).returns(T.attached_class) }
    def self.from_json(input)
      new(Serde::JSON.new.deserialize(input))
    end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby
      Backend::Ruby.compile(expr)
    end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(ActiveRecord::Relation) }
    def to_arel(model)
      Backend::Arel.compile(model, expr)
    end

    sig { returns(String) }
    def to_json
      Serde::JSON.new.serialize(expr)
    end

    sig { params(model: T.class_of(ActiveRecord::Base)).returns(Validation::Result) }
    def validate(model)
      Validation.validate(model, expr)
    end

    private

    sig { returns(DSL::BoolExpr) }
    attr_reader :expr
  end
end
