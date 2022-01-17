# typed: strict

module FQL
  module Backend
    module Ruby
      extend T::Sig

      CompiledFunction = T.type_alias do
        T.proc.params(
          arg0: T.untyped, # __itself__
          arg1: T::Hash[Symbol, T.untyped] #__fql_vars__
        ).returns(T::Boolean)
      end

      sig { params(expr: Query::DSL::BoolExpr).returns(CompiledFunction) }
      def self.compile(expr)
        code = "proc { |__itself__, __fql_vars__| #{compile_expression(expr)} }"
        RubyVM::InstructionSequence.compile(code).eval
      end

      sig { params(expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr)).returns(String) }
      def self.compile_expression(expr)
        case expr
        when true, false
          "#{expr}"
        when Integer
          "#{expr}"
        when String
          "\"#{expr}\""
        when Date
          "Date.parse(\"#{expr.to_s}\")"
        when Query::DSL::And
          "(#{compile_expression(T.let(expr.lhs, Query::DSL::BoolExpr))} && #{compile_expression(T.let(expr.rhs, Query::DSL::BoolExpr))})"
        when Query::DSL::Or
          "(#{compile_expression(T.let(expr.lhs, Query::DSL::BoolExpr))} || #{compile_expression(T.let(expr.rhs, Query::DSL::BoolExpr))})"
        when Query::DSL::Not
          "!#{compile_expression(T.let(expr.expr, Query::DSL::BoolExpr))}"
        when Query::DSL::Eq, Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
            when Query::DSL::Eq then '=='
            when Query::DSL::Gt then '>'
            when Query::DSL::Gte then '>='
            when Query::DSL::Lt then '<'
            when Query::DSL::Lte then '<='
          end
          "(#{compile_expression(T.let(expr.lhs, Query::DSL::ValueExpr))} #{operator} #{compile_expression(T.let(expr.rhs, Query::DSL::ValueExpr))})"
        when Query::DSL::Contains
          "#{compile_expression(expr.lhs)}.include?(#{compile_expression(expr.rhs)})"
        when Query::DSL::Rel
          if expr.name == :self
            '__itself__'
          else
            expr.name.to_s
          end
        when Query::DSL::Attr
          "#{'__itself__.' unless expr.target.name == :self}#{compile_expression(expr.target)}.#{expr.name.to_s}"
        when Query::DSL::Var
          "__fql_vars__[#{expr.name.inspect}]"
        when Query::DSL::BoolExpr, Query::DSL::ValueExpr
          compile_expression(expr)
        else
          T.absurd(expr)
        end
      end
    end
  end
end
