# typed: false
require 'spec_helper'
require 'ostruct'

RSpec.describe FQL::Backend::Ruby do
  matcher :compile_to do |expected|
    match do |expression|
      FQL::Backend::Ruby.compile_expression(expression) == expected
    end
    failure_message do |expression|
      "expected #{expression.inspect} to compile to \"#{expected}\", but got \"#{FQL::Backend::Ruby.compile_expression(expression)}\" instead"
    end
  end

  let(:complex_query) do
    FQL::Query::Or.new(
      lhs: FQL::Query::Eq.new(
        lhs: FQL::Query::Attr.new(
          target: FQL::Query::Rel.new(name: :location),
          name: :country
        ),
        rhs: 'es'
      ),
      rhs: FQL::Query::Gt.new(
        lhs: FQL::Query::Attr.new(
          target: FQL::Query::Rel.new(name: :salary),
          name: :amount
        ),
        rhs: FQL::Query::Var.new(name: :threshold)
      )
    )
  end

  describe '.compile' do
    it 'compiles a complex query to a Ruby proc' do
      fn = FQL::Backend::Ruby.compile(complex_query)
      target = OpenStruct.new({
        location: OpenStruct.new({
          country: "fr"
        }),
        salary: OpenStruct.new({
          amount: 28000
        })
      })
      expect(fn.call(target, {threshold: 24000})).to eq(true)
    end
  end

  describe '.compile_expression' do
    it 'compiles a complex query to a Ruby expression' do
      expect(complex_query).to compile_to('((__itself__.location.country == "es") || (__itself__.salary.amount > __fql_vars__[:threshold]))')
    end

    describe 'primitive values' do
      it 'compile to themselves' do
        expect(true).to compile_to('true')
        expect(false).to compile_to('false')
        expect(5).to compile_to('5')
        expect('hello').to compile_to('"hello"')
      end
    end

    describe 'And' do
      it 'compiles to &&' do
        expect(FQL::Query::And.new(lhs: true, rhs: false)).to compile_to('(true && false)')
      end
    end

    describe 'Or' do
      it 'compiles to ||' do
        expect(FQL::Query::Or.new(lhs: true, rhs: false)).to compile_to('(true || false)')
      end
    end

    describe 'Not' do
      it 'compiles to !' do
        expect(FQL::Query::Not.new(expr: true)).to compile_to('!true')
      end
    end

    describe 'Eq' do
      it 'compiles to ==' do
        expect(FQL::Query::Eq.new(lhs: true, rhs: false)).to compile_to('(true == false)')
      end
    end

    describe 'Gt' do
      it 'compiles to >' do
        expect(FQL::Query::Gt.new(lhs: 5, rhs: 2)).to compile_to('(5 > 2)')
      end
    end

    describe 'Gte' do
      it 'compiles to >=' do
        expect(FQL::Query::Gte.new(lhs: 5, rhs: 2)).to compile_to('(5 >= 2)')
      end
    end

    describe 'Lt' do
      it 'compiles to <' do
        expect(FQL::Query::Lt.new(lhs: 5, rhs: 2)).to compile_to('(5 < 2)')
      end
    end

    describe 'Lte' do
      it 'compiles to <=' do
        expect(FQL::Query::Lte.new(lhs: 5, rhs: 2)).to compile_to('(5 <= 2)')
      end
    end

    describe 'Rel' do
      context 'when the name refers to self' do
        it 'compiles to the special reference __itself__' do
          expect(FQL::Query::Rel.new(name: :self)).to compile_to('__itself__')
        end
      end

      context 'when the name does not refer to self' do
        it 'compiles to its name' do
          expect(FQL::Query::Rel.new(name: :location)).to compile_to('location')
        end
      end
    end

    describe 'Attr' do
      it 'compiles to a qualified method call' do
        expect(FQL::Query::Attr.new(target: FQL::Query::Rel.new(name: :self), name: :property)).to compile_to('__itself__.property')
        expect(FQL::Query::Attr.new(target: FQL::Query::Rel.new(name: :location), name: :property)).to compile_to('__itself__.location.property')
      end
    end

    describe 'Var' do
      it 'compiles to a var lookup' do
        expect(FQL::Query::Var.new(name: :username)).to compile_to('__fql_vars__[:username]')
      end
    end
  end
end
