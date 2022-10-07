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

      sig { params(expr: Query::DSL::BoolExpr, library: Library).returns(CompiledFunction) }
      def self.compile(expr, library:)
        code = "proc { |__itself__, __fql_vars__| #{compile_expression(expr, library)} }"
        RubyVM::InstructionSequence.compile(code).eval
      end

      sig do
        params(
          expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr, NilClass,
                      T::Array[Query::DSL::Primitive]),
          lib: Library
        ).returns(String)
      end
      def self.compile_expression(expr, lib)
        case expr
        when true, false, Integer
          expr.to_s
        when nil
          "nil"
        when String
          "\"#{expr}\""
        when Array
          "[#{expr.map { |e| compile_expression(e, lib) }.join(', ')}]"
        when Date
          "Date.parse(\"#{expr}\")"
        when Query::DSL::And
          "(#{compile_expression(T.let(expr.lhs,
                                       Query::DSL::BoolExpr), lib)} && #{compile_expression(T.let(expr.rhs, Query::DSL::BoolExpr), lib)})"
        when Query::DSL::Or
          "(#{compile_expression(T.let(expr.lhs,
                                       Query::DSL::BoolExpr), lib)} || #{compile_expression(T.let(expr.rhs, Query::DSL::BoolExpr), lib)})"
        when Query::DSL::Not
          "!#{compile_expression(T.let(expr.expr, Query::DSL::BoolExpr), lib)}"
        when Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
                     when Query::DSL::Gt then ">"
                     when Query::DSL::Gte then ">="
                     when Query::DSL::Lt then "<"
                     when Query::DSL::Lte then "<="
                     end

          lhs = compile_expression(T.let(expr.lhs, Query::DSL::ValueExpr), lib)
          rhs = compile_expression(T.let(expr.rhs, Query::DSL::ValueExpr), lib)

          "(#{lhs} #{operator} #{rhs})"
        when Query::DSL::Eq
          "(#{compile_expression(expr.lhs, lib)} == #{compile_expression(expr.rhs, lib)})"
        when Query::DSL::OneOf
          "#{compile_expression(expr.set, lib)}.include?(#{compile_expression(expr.member, lib)})"
        when Query::DSL::Contains
          "#{compile_expression(expr.lhs, lib)}.include?(#{compile_expression(expr.rhs, lib)})"
        when Query::DSL::MatchesRegex
          "#{compile_expression(expr.lhs, lib)}.match(/#{expr.rhs}/)"
        when Query::DSL::Rel
          if expr.name == [:self]
            "__itself__"
          else
            expr.name.map(&:to_s).join(".")
          end
        when Query::DSL::Attr
          "#{'__itself__.' unless expr.target.name == [:self]}#{compile_expression(expr.target, lib)}.#{expr.name}"
        when Query::DSL::Var
          "__fql_vars__[#{expr.name.inspect}]"
        when Query::DSL::Call
          found = lib.call(expr.name, expr.arguments)
          raise ArgumentError, "The library function #{expr.name} errored" unless found

          compile_expression(found, lib)
        else
          T.absurd(expr)
        end
      end
    end
  end
end
