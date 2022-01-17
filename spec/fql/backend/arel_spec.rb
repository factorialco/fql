# typed: xtrue
require 'spec_helper'

RSpec.describe FQL::Backend::Arel do
  module F
    extend FQL::Query::DSL
  end

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

  class User < ActiveRecord::Base
    has_one :address, foreign_key: :tenant_id
  end

  class Address < ActiveRecord::Base
    belongs_to :user, foreign_key: :tenant_id
  end

  subject { described_class.new(User, {}) }

  describe '.compile_expression' do
    describe 'primitive values' do
      it 'compile to themselves' do
        expect(true).to compile_to('SELECT "users".* FROM "users" WHERE 1')
        expect(false).to compile_to('SELECT "users".* FROM "users" WHERE 0')
        expect(5).to raw_compile_to(5)
        expect('hello').to raw_compile_to('hello')
        today = Date.today
        expect(today).to raw_compile_to(today)
      end end

    describe 'And' do
      it 'compiles to AND' do
        expect(F.and(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 AND 0')
      end
    end

    describe 'Or' do
      it 'compiles to OR' do
        expect(F.or(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE (1 OR 0)')
      end
    end

    describe 'Not' do
      it 'compiles to NOT' do
        expect(F.not(true)).to compile_to('SELECT "users".* FROM "users" WHERE NOT (1)')
      end
    end

    describe 'Eq' do
      it 'compiles to =' do
        expect(F.eq(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 = 0')
      end
    end

    describe 'Gt' do
      it 'compiles to >' do
        expect(F.gt(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 > 0')
      end
    end

    describe 'Gte' do
      it 'compiles to >=' do
        expect(F.gte(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 >= 0')
      end
    end

    describe 'Lt' do
      it 'compiles to <' do
        expect(F.lt(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 < 0')
      end
    end

    describe 'Lte' do
      it 'compiles to <=' do
        expect(F.lte(true, false)).to compile_to('SELECT "users".* FROM "users" WHERE 1 <= 0')
      end
    end

    describe 'Contains' do
      it 'compiles to matches' do
        expect(F.contains(F.attr(F.rel(:self), :first_name), "thing")).to compile_to('SELECT "users".* FROM "users" WHERE "users"."first_name" LIKE \'%thing%\'')
      end
    end

    describe 'Rel + Attr' do
      context 'when the name refers to self' do
        it 'compiles to the main table attribute' do
          expect(F.eq(F.attr(F.rel(:self), :first_name), "Juanito")).to compile_to("SELECT \"users\".* FROM \"users\" WHERE \"users\".\"first_name\" = 'Juanito'")
        end
      end

      context 'when the name does not refer to self' do
        it 'compiles to a join query' do
          expect(F.eq(F.attr(F.rel(:address), :country), "es")).to compile_to('SELECT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'es\'')
        end
      end
    end

    describe 'Var' do
      subject { described_class.new(User, {country: 'fr'}) }

      it 'lookups up a variable at compile time' do
        expect(F.eq(F.attr(F.rel(:address), :country), F.var(:country))).to compile_to('SELECT "users".* FROM "users" INNER JOIN addresses "address" ON "users"."id" = "address"."tenant_id" WHERE "address"."country" = \'fr\'')
      end

      context 'when the variable does not exist at compile time' do
        it 'raises an exception' do
          expect {
            subject.compile_expression(F.var(:foo))
          }.to raise_error(/key not found/)
        end
      end
    end
  end
end
