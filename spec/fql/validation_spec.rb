# typed: false
require "spec_helper"

RSpec.describe FQL::Validation do
  F = FQL::Query::DSL unless defined?(F)

  matcher :pass do |_expected|
    match do |expression|
      described_class.validate(model, expression).valid?
    end

    failure_message do |expression|
      result = described_class.validate(model, expression)
      "expected #{expression.inspect} to pass, but it failed with these errors instead: #{result.errors.join(', ')}"
    end
  end

  matcher :fail_with do |expected|
    match do |expression|
      described_class.validate(model, expression).errors.include?(expected)
    end

    failure_message do |expression|
      out = "expected #{expression.inspect} to fail with \"#{expected}\", but "
      result = described_class.validate(model, expression)
      out += if result.valid?
               " it didn't fail at all"
             else
               " it failed with these errors instead: #{result.errors.join(', ')}"
             end
      out
    end
  end

  describe ".validate" do
    context "when an expression is valid" do
      let(:model) { User }
      let(:expression) do
        F.eq(
          F.attr(
            F.rel(%i[address city]),
            :name
          ),
          "Barcelona"
        )
      end

      it "passes with flying colors" do
        expect(expression).to pass
      end
    end

    context "when an expression refers to an attribute that does not exist on self" do
      let(:model) { User }
      let(:expression) do
        F.eq(
          F.attr(
            F.rel(%i[self]),
            :nonsense
          ),
          "hello"
        )
      end

      it "fails" do
        expect(expression).to fail_with "User does not contain attribute nonsense"
      end
    end

    context "when an expression refers to a relation that does not resolve" do
      let(:model) { User }
      let(:expression) do
        F.eq(
          F.attr(
            F.rel(%i[nonsense]),
            :name
          ),
          "hello"
        )
      end

      it "fails" do
        expect(expression).to fail_with "model User has no association nonsense"
      end

      context "when the relation is deep" do
        let(:expression) do
          F.eq(
            F.attr(
              F.rel(%i[address planet]),
              :name
            ),
            "hello"
          )
        end

        it "fails" do
          expect(expression).to fail_with "model Address has no association planet"
        end
      end

      context "when the relation is really very deep" do
        let(:expression) do
          F.eq(
            F.attr(
              F.rel(%i[address planet galaxy constellation]),
              :name
            ),
            "hello"
          )
        end

        it "fails" do
          expect(expression).to fail_with "model Address has no association planet"
        end
      end
    end
  end
end
