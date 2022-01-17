# typed: strict
require 'active_record'
require 'sorbet-rails'

module FQL
  class Query
    extend T::Sig

    sig { params(expr: DSL::BoolExpr).void }
    def initialize(expr)
      @expr = expr
    end

    sig { returns(Backend::Ruby::CompiledFunction) }
    def to_ruby
      Backend::Ruby.compile(expr)
    end

    sig { params(model: ActiveRecord::Base, expr: DSL::BoolExpr).returns(String) }
    def to_arel(model, expr)
      Backend::Arel.compile(model, expr)
    end

    private

    sig { returns(DSL::BoolExpr) }
    attr_reader :expr
  end
end
