# typed: false
require "spec_helper"

RSpec.describe FQL::Backend::Ruby do
  F = FQL::Query::DSL

  matcher :compile_to do |expected|
    match do |expression|
      described_class.compile_expression(expression) == expected
    end
    failure_message do |expression|
      "expected #{expression.inspect} to compile to \"#{expected}\", but got \"#{described_class.compile_expression(expression)}\" instead"
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
    it "compiles a complex query to a Ruby proc" do
      fn = described_class.compile(complex_query)
      target = double({
                        location: double({
                                           country: "fr"
                                         }),
                        salary:   double({
                                           amount: 28_000
                                         })
                      })
      expect(fn.call(target, { threshold: 24_000 })).to eq(true)
    end
  end

  describe ".compile_expression" do
    it "compiles a complex query to a Ruby expression" do
      expect(complex_query).to compile_to('((__itself__.location.country == "es") || (__itself__.salary.amount > __fql_vars__[:threshold]))')
    end

    describe "primitive values" do
      it "compile to themselves" do
        expect(true).to compile_to("true")
        expect(false).to compile_to("false")
        expect(5).to compile_to("5")
        expect("hello").to compile_to('"hello"')
        today = Date.today
        expect(today).to compile_to("Date.parse(\"#{today}\")")
      end
    end

    describe "And" do
      it "compiles to &&" do
        expect(F.and(true, false)).to compile_to("(true && false)")
      end
    end

    describe "Or" do
      it "compiles to ||" do
        expect(F.or(true, false)).to compile_to("(true || false)")
      end
    end

    describe "Not" do
      it "compiles to !" do
        expect(F.not(true)).to compile_to("!true")
      end
    end

    describe "Eq" do
      it "compiles to ==" do
        expect(F.eq(true, false)).to compile_to("(true == false)")
      end
    end

    describe "Gt" do
      it "compiles to >" do
        expect(F.gt(5, 2)).to compile_to("(5 > 2)")
      end
    end

    describe "Gte" do
      it "compiles to >=" do
        expect(F.gte(5, 2)).to compile_to("(5 >= 2)")
      end
    end

    describe "Lt" do
      it "compiles to <" do
        expect(F.lt(5, 2)).to compile_to("(5 < 2)")
      end
    end

    describe "Lte" do
      it "compiles to <=" do
        expect(F.lte(5, 2)).to compile_to("(5 <= 2)")
      end
    end

    describe "Contains" do
      it "compiles to include?" do
        expect(F.contains("Something", "thing")).to compile_to('"Something".include?("thing")')
      end
    end

    describe "Match regex" do
      it "compiles to match" do
        expect(F.matches_regex("Something", "thing")).to compile_to('"Something".match(/thing/)')
      end
    end

    describe "Rel" do
      context "when the name refers to self" do
        it "compiles to the special reference __itself__" do
          expect(F.rel(:self)).to compile_to("__itself__")
        end
      end

      context "when the name does not refer to self" do
        it "compiles to its name" do
          expect(F.rel(:location)).to compile_to("location")
        end
      end

      context "when the rel is deeply nested" do
        it "compiles to a nested method call" do
          expect(
            F.eq(
              F.attr(
                F.rel(%i[address city]),
                :name
              ),
              "Barcelona"
            )
          ).to compile_to('(__itself__.address.city.name == "Barcelona")')
        end
      end
    end

    describe "Attr" do
      it "compiles to a qualified method call" do
        expect(F.attr(F.rel(:self), :property)).to compile_to("__itself__.property")
        expect(F.attr(F.rel(:location), :property)).to compile_to("__itself__.location.property")
      end
    end

    describe "Var" do
      it "compiles to a var lookup" do
        expect(F.var(:username)).to compile_to("__fql_vars__[:username]")
      end
    end
  end
end
