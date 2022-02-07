# typed: strict

module FQL
  module Backend
    module Ruby
      extend T::Sig

      CompiledFunction = T.type_alias do
        T.proc.params(
          arg0: T.untyped, # __itself__
          arg1: T::Hash[Symbol, T.untyped] # __fql_vars__
        ).returns(T::Boolean)
      end

      sig { params(expr: Query::DSL::BoolExpr).returns(CompiledFunction) }
      def self.compile(expr)
        code = "proc { |__itself__, __fql_vars__| #{compile_expression(expr)} }"
        RubyVM::InstructionSequence.compile(code).eval
      end

      sig do
        params(expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr, NilClass,
                           T::Array[Query::DSL::Primitive])).returns(String)
      end
      def self.compile_expression(expr)
        case expr
        when true, false, Integer
          expr.to_s
        when nil
          "nil"
        when String
          "\"#{expr}\""
        when Array
          "[#{expr.map { |e| compile_expression(e) }.join(', ')}]"
        when Date
          "Date.parse(\"#{expr}\")"
        when Query::DSL::And
          "(#{compile_expression(T.let(expr.lhs,
                                       Query::DSL::BoolExpr))} && #{compile_expression(T.let(expr.rhs,
                                                                                             Query::DSL::BoolExpr))})"
        when Query::DSL::Or
          "(#{compile_expression(T.let(expr.lhs,
                                       Query::DSL::BoolExpr))} || #{compile_expression(T.let(expr.rhs,
                                                                                             Query::DSL::BoolExpr))})"
        when Query::DSL::Not
          "!#{compile_expression(T.let(expr.expr, Query::DSL::BoolExpr))}"
        when Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
                     when Query::DSL::Gt then ">"
                     when Query::DSL::Gte then ">="
                     when Query::DSL::Lt then "<"
                     when Query::DSL::Lte then "<="
                     end

          lhs = compile_expression(T.let(expr.lhs, Query::DSL::ValueExpr))
          rhs = compile_expression(T.let(expr.rhs, Query::DSL::ValueExpr))

          "(#{lhs} #{operator} #{rhs})"
        when Query::DSL::Eq
          "(#{compile_expression(expr.lhs)} == #{compile_expression(expr.rhs)})"
        when Query::DSL::OneOf
          "#{compile_expression(expr.set)}.include?(#{compile_expression(expr.member)})"
        when Query::DSL::Contains
          "#{compile_expression(expr.lhs)}.include?(#{compile_expression(expr.rhs)})"
        when Query::DSL::MatchesRegex
          "#{compile_expression(expr.lhs)}.match(/#{expr.rhs}/)"
        when Query::DSL::Rel
          if expr.name == [:self]
            "__itself__"
          else
            expr.name.map(&:to_s).join(".")
          end
        when Query::DSL::Attr
          "#{'__itself__.' unless expr.target.name == [:self]}#{compile_expression(expr.target)}.#{expr.name}"
        when Query::DSL::Var
          "__fql_vars__[#{expr.name.inspect}]"
        else
          T.absurd(expr)
        end
      end
    end
  end
end
