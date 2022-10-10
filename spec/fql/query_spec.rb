# typed: false
require "spec_helper"

RSpec.describe FQL::Query do
  F = FQL::Query::DSL unless defined?(F)

  subject(:query) { described_class.new(expression) }

  describe "composition" do
    let(:expression) do
      F.eq(F.var(:foo), 3)
    end

    let(:another_expression) do
      F.eq(F.var(:foo), 3)
    end

    it "#and combines two queries" do
      result = query.and(another_expression).send(:expr)
      expect(result).to eq(F.and(expression, another_expression))
    end

    it "#or combines two queries" do
      result = query.or(another_expression).send(:expr)
      expect(result).to eq(F.or(expression, another_expression))
    end

    it "#not negates a query" do
      result = query.not.send(:expr)
      expect(result).to eq(F.not(expression))
    end
  end

  describe "metadata" do
    let(:expression) do
      F.eq(
        F.with_meta({ name: "the user id" }, F.var(:foo)),
        3
      )
    end

    it "can be attached to an arbitrary node" do
      expect(expression.lhs.metadata).to eq(name: "the user id")
    end
  end
end
