# typed: strict

module FQL
  module Backend
    class Words
      extend T::Sig

      sig { params(expr: Query::DSL::BoolExpr).returns(String) }
      def self.compile(expr)
        compile_expression(expr)
      end

      sig { params(expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr), negated: T::Boolean).returns(String) }
      def self.compile_expression(expr, negated: false)
        case expr
        when true, false, Integer
          expr.to_s
        when nil
          "null"
        when String
          "\"#{expr}\""
        when Date
          expr.strftime("%B %d, %Y")
        when Query::DSL::And
          I18n.t(
            negated ? "fql.not_both" : "fql.both",
            left: compile_expression(expr.lhs),
            right: compile_expression(expr.rhs)
          )
        when Query::DSL::Or
          I18n.t(
            negated ? "fql.neither" : "fql.either",
            left: compile_expression(expr.lhs),
            right: compile_expression(expr.rhs)
          )
        when Query::DSL::Not
          compile_expression(expr.expr, negated: true)
        when Query::DSL::Eq
          if expr.rhs.nil?
            key = negated ? "fql.is_not_empty" : "fql.is_empty"
            I18n.t(
              key,
              noun: compile_expression(expr.lhs)
            )
          else
            key = negated ? "fql.does_not_equal" : "fql.equals"
            I18n.t(
              key,
              left: compile_expression(expr.lhs),
              right: compile_expression(T.cast(expr.rhs, Query::DSL::ValueExpr))
            )
          end
        when Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
                     when Query::DSL::Gt then "greater_than"
                     when Query::DSL::Gte then "greater_than_or_equals"
                     when Query::DSL::Lt then "less_than"
                     when Query::DSL::Lte then "less_than_or_equals"
                     end

          operator = "not_#{operator}" if negated

          I18n.t(
            "fql.#{operator}",
            left: compile_expression(expr.lhs),
            right: compile_expression(expr.rhs)
          )
        when Query::DSL::Contains
          I18n.t(
            negated ? "fql.does_not_contain" : "fql.contains",
            left: compile_expression(expr.lhs),
            right: compile_expression(expr.rhs)
          )
        when Query::DSL::MatchesRegex
          I18n.t(
            negated ? "fql.does_not_match" : "fql.matches",
            left: compile_expression(expr.lhs),
            right: compile_expression(expr.rhs)
          )
        when Query::DSL::Rel
          expr.name.reverse.map do |noun|
            I18n.t(
              "fql.genitive",
              noun: I18n.t("fql.attributes.#{noun}")
            )
          end.join(" ")
        when Query::DSL::Attr
          if expr.target.name == [:self]
            I18n.t(
              "fql.own_attribute",
              name: I18n.t("fql.attributes.#{expr.name}")
            )
          else
            I18n.t(
              "fql.attribute",
              name: I18n.t("fql.attributes.#{expr.name}"),
              owner: compile_expression(expr.target)
            )
          end
        when Query::DSL::Var
          I18n.t(
            "fql.variable",
            name: I18n.t("fql.attributes.#{expr.name}")
          )
        else
          T.absurd(expr)
        end
      end
    end
  end
end
