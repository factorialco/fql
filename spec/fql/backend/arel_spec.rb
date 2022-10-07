# typed: false
require "spec_helper"

RSpec.describe FQL::Backend::Arel do
  F = FQL::Query::DSL unless defined?(F)

  matcher :compile_to do |expected|
    match do |expression|
      subject.compile(expression).to_sql == expected
    end
    failure_message do |expression|
      "expected #{expression.inspect} to compile to \"#{expected}\", but got \"#{subject.compile(expression).to_sql}\" instead"
    end
  end

  matcher :raw_compile_to do |expected|
    match do |expression|
      subject.compile_expression(expression) == expected
    end
    failure_message do |expression|
      "expected #{expression.inspect} to compile to \"#{expected}\", but got \"#{subject.compile_expression(expression)}\" instead"
    end
  end

  subject { described_class.new(User, vars: {}, library: library) }

  let(:library) { TestUserLibrary.new }

  describe ".compile_expression" do
    describe "primitive values" do
      it "compile to themselves" do
        expect(true).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1')
        expect(false).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 0')
        expect(5).to raw_compile_to(5)
        expect("hello").to raw_compile_to("hello")
        today = Date.today
        expect(today).to raw_compile_to(today)
      end
    end

    describe "And" do
      it "compiles to AND" do
        expect(F.and(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 AND 0')
      end
    end

    describe "Or" do
      it "compiles to OR" do
        expect(F.or(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE (1 OR 0)')
      end
    end

    describe "Not" do
      it "compiles to NOT" do
        expect(F.not(true)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE NOT (1)')
      end
    end

    describe "Eq" do
      it "compiles to =" do
        expect(F.eq(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 = 0')
      end

      it "accepts nil on the right hand side" do
        expect(F.eq(true, nil)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 IS NULL')
      end

      it "handles IS NOT NULL" do
        expect(F.not(F.eq(true, nil))).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE NOT (1 IS NULL)')
      end
    end

    describe "Gt" do
      it "compiles to >" do
        expect(F.gt(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 > 0')
      end
    end

    describe "Gte" do
      it "compiles to >=" do
        expect(F.gte(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 >= 0')
      end
    end

    describe "Lt" do
      it "compiles to <" do
        expect(F.lt(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 < 0')
      end
    end

    describe "Lte" do
      it "compiles to <=" do
        expect(F.lte(true, false)).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE 1 <= 0')
      end
    end

    describe "OneOf" do
      it "compiles to in" do
        expect(F.one_of(F.attr(F.rel(:self), :first_name), %w[this that])).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE "users"."first_name" IN (\'this\', \'that\')')
      end
    end

    describe "Contains" do
      it "compiles to like" do
        expect(F.contains(F.attr(F.rel(:self), :first_name), "thing")).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE "users"."first_name" LIKE \'%thing%\'')
      end
    end

    describe "Matches regex" do
      xit "compiles to matches_regexp" do
        expect(F.matches_regex(F.attr(F.rel(:self), :first_name), "thing")).to compile_to('SELECT DISTINCT "users".* FROM "users" WHERE "users"."first_name" REGEXP \'thing\'')
      end
    end

    describe "Rel + Attr" do
      context "when the name refers to self" do
        it "compiles to the main table attribute" do
          expect(F.eq(F.attr(F.rel(:self), :first_name), "Juanito")).to compile_to("SELECT DISTINCT \"users\".* FROM \"users\" WHERE \"users\".\"first_name\" = 'Juanito'")
        end
      end

      context "when the name does not refer to self" do
        it "compiles to a join query" do
          expect(F.eq(F.attr(F.rel(:address), :country), "es")).to compile_to('SELECT DISTINCT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'es\'')
        end
      end

      context "when the rel is deeply nested" do
        it "compiles to a complex join query" do
          expect(
            F.eq(
              F.attr(
                F.rel(%i[address city]),
                :name
              ),
              "Barcelona"
            )
          ).to compile_to(
            [
              'SELECT DISTINCT "users".* FROM "users"',
              'INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id"',
              'INNER JOIN cities "city" ON "address"."city_id" = "city"."id"',
              'WHERE "city"."name" = \'Barcelona\''
            ].join(" ")
          )
        end
      end
    end

    describe "Var" do
      subject { described_class.new(User, vars: { country: "fr" }, library: library) }

      it "lookups up a variable at compile time" do
        expect(F.eq(F.attr(F.rel(:address), :country), F.var(:country))).to compile_to('SELECT DISTINCT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'fr\'')
      end

      context "when the variable does not exist at compile time" do
        it "raises an exception" do
          expect do
            subject.compile_expression(F.var(:foo))
          end.to raise_error(/key not found/)
        end
      end
    end

    context "with a custom library" do
      subject { described_class.new(User, vars: {}, library: library) }

      it "can call a simple function from the library" do
        expect(F.eq(F.call(:country), "fr")).to compile_to('SELECT DISTINCT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'fr\'')
      end

      it "can call a parameterized function from the library" do
        expect(F.eq(F.call(:country), F.call(:echo, "fr"))).to compile_to('SELECT DISTINCT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'fr\'')
      end

      it "can call a parameterized boolean function from the library" do
        expect(F.call(:my_eq, F.attr(F.rel(:self), :first_name), "Juanito")).to compile_to("SELECT DISTINCT \"users\".* FROM \"users\" WHERE \"users\".\"first_name\" = 'Juanito'")
      end
    end
  end
end
