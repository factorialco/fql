# typed: false
require "spec_helper"

RSpec.describe FQL::Backend::Words do
  F = FQL::Query::DSL unless defined?(F)

  matcher :compile_to do |expected|
    match do |expression|
      described_class.compile_expression(expression) == expected
    end
    failure_message do |expression|
      result = described_class.compile_expression(expression)
      "expected #{expression.inspect} to compile to '#{expected}', but got '#{result}' instead"
    end
  end

  let(:complex_query) do
    F.or(
      F.eq(
        F.attr(
          F.rel(:location),
          :country
        ),
        "es"
      ),
      F.gt(
        F.attr(
          F.rel(:salary),
          :amount
        ),
        F.var(:threshold)
      )
    )
  end

  describe ".compile" do
    it "compiles a complex query to natural language" do
      expect(described_class.compile(complex_query)).to eq(
        "EITHER (the country of the location equals \"es\") OR (the amount of the salary is greater than a given threshold)"
      )
    end

    context "with a special suffix" do
      it "compiles a complex query to natural language accordingly" do
        expect(described_class.compile(complex_query, suffix: "html")).to eq(
          "<strong>EITHER</strong> (the country of the location equals \"es\") <strong>OR</strong> (the amount of the salary is greater than a given threshold)"
        )
      end
    end
  end

  describe ".compile_expression" do
    describe "primitive values" do
      it "compile to themselves" do
        expect(true).to compile_to("true")
        expect(false).to compile_to("false")
        expect(5).to compile_to("5")
        expect("hello").to compile_to('"hello"')
        today = Date.today
        expect(today).to compile_to(today.strftime("%B %d, %Y"))
      end
    end

    describe "And" do
      it "compiles to BOTH ... AND" do
        expect(F.and(true, false)).to compile_to(
          "BOTH (true) AND (false)"
        )
      end

      it "negated it compiles to NOT BOTH ... AND" do
        expect(F.not(F.and(true, false))).to compile_to(
          "NOT BOTH (true) AND (false)"
        )
      end
    end

    describe "Or" do
      it "compiles to EITHER ... OR" do
        expect(F.or(true, false)).to compile_to(
          "EITHER (true) OR (false)"
        )
      end

      it "negated it compiles to EITHER ... NOR" do
        expect(F.not(F.or(true, false))).to compile_to(
          "NEITHER (true) NOR (false)"
        )
      end
    end

    describe "Eq" do
      it "compiles to equals" do
        expect(F.eq(true, false)).to compile_to("true equals false")
      end

      it "compiles to does not equal" do
        expect(F.not(F.eq(true, false))).to compile_to("true does not equal false")
      end

      it "accepts null on the right hand side" do
        expect(F.eq(true, nil)).to compile_to("true is empty")
      end

      it "handles the negative case of empty" do
        expect(F.not(F.eq(true, nil))).to compile_to("true is not empty")
      end
    end

    describe "Gt" do
      it "compiles to >" do
        expect(F.gt(5, 2)).to compile_to("5 is greater than 2")
      end
    end

    describe "Gte" do
      it "compiles to >=" do
        expect(F.gte(5, 2)).to compile_to("5 is greater than (or equals) 2")
      end
    end

    describe "Lt" do
      it "compiles to <" do
        expect(F.lt(5, 2)).to compile_to("5 is less than 2")
      end
    end

    describe "Lte" do
      it "compiles to <=" do
        expect(F.lte(5, 2)).to compile_to("5 is less than (or equals) 2")
      end
    end

    describe "OneOf" do
      it "compiles to is one of" do
        expect(F.one_of("Hello", %w[Hello Goodbye])).to compile_to('"Hello" is one of ["Hello", "Goodbye"]')
      end
    end

    describe "Contains" do
      it "compiles to contains" do
        expect(F.contains("Something", "thing")).to compile_to('"Something" contains "thing"')
      end
    end

    describe "Match regex" do
      it "compiles to matches" do
        expect(F.matches_regex("Something", "thing")).to compile_to('"Something" matches "thing"')
      end
    end

    describe "Rel" do
      context "when the name does not refer to self" do
        it "compiles to the target's genitive" do
          expect(F.rel(:location)).to compile_to("of the location")
        end
      end

      context "when the rel is deeply nested" do
        it "compiles to a nested reference" do
          expect(
            F.eq(
              F.attr(
                F.rel(%i[address city]),
                :name
              ),
              "Barcelona"
            )
          ).to compile_to("the name of the city of the address equals \"Barcelona\"")
        end
      end
    end

    describe "Attr" do
      it "compiles to a qualified reference" do
        expect(F.attr(F.rel(:self), :property)).to compile_to("their property")
        expect(F.attr(F.rel(:location), :property)).to compile_to("the property of the location")
      end
    end

    describe "Var" do
      it "compiles to a var lookup" do
        expect(F.var(:username)).to compile_to("a given username")
      end
    end
  end
end
