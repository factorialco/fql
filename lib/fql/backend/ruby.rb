# typed: strict

module FQL
  module Backend
    module Ruby
      extend T::Sig

      CompiledFunction = T.type_alias { T.proc.params(arg0: T.untyped, arg1: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }

      sig { params(expr: Query::BoolExpr).returns(CompiledFunction) }
      def self.compile(expr)
        code = "proc { |__itself__, __fql_vars__| #{compile_expression(expr)} }"
        RubyVM::InstructionSequence.compile(code).eval
      end

      sig { params(expr: T.any(Query::BoolExpr, Query::ValueExpr)).returns(String) }
      def self.compile_expression(expr)
        case expr
        when true, false
          "#{expr}"
        when Integer
          "#{expr}"
        when String
          "\"#{expr}\""
        when Query::And
          "(#{compile_expression(T.let(expr.lhs, Query::BoolExpr))} && #{compile_expression(T.let(expr.rhs, Query::BoolExpr))})"
        when Query::Or
          "(#{compile_expression(T.let(expr.lhs, Query::BoolExpr))} || #{compile_expression(T.let(expr.rhs, Query::BoolExpr))})"
        when Query::Not
          "!#{compile_expression(T.let(expr.expr, Query::BoolExpr))}"
        when Query::Eq, Query::Gt, Query::Gte, Query::Lt, Query::Lte
          operator = case expr
            when Query::Eq then '=='
            when Query::Gt then '>'
            when Query::Gte then '>='
            when Query::Lt then '<'
            when Query::Lte then '<='
          end
          "(#{compile_expression(T.let(expr.lhs, Query::ValueExpr))} #{operator} #{compile_expression(T.let(expr.rhs, Query::ValueExpr))})"
        when Query::Rel
          if expr.name == :self
            '__itself__'
          else
            expr.name.to_s
          end
        when Query::Attr
          "#{'__itself__.' unless expr.target.name == :self}#{compile_expression(expr.target)}.#{expr.name.to_s}"
        when Query::Var
          "__fql_vars__[#{expr.name.inspect}]"
        else
          raise "don't know how to compile #{expr.inspect}"
        end
      end
    end
  end
end
