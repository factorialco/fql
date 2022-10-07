# typed: strict

module FQL
  module Backend
    class Words
      extend T::Sig

      sig { params(expr: Query::DSL::BoolExpr, suffix: T.nilable(String), library: Library).returns(String) }
      def self.compile(expr, suffix: nil, library: Library.empty)
        compile_expression(expr, negated: false, suffix: suffix, library: library)
      end

      sig do
        params(
          expr: T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr),
          negated: T::Boolean,
          suffix: T.nilable(String),
          library: Library
        ).returns(String)
      end
      def self.compile_expression(expr, negated: false, suffix: nil, library: Library.empty)
        case expr
        when true, false, Integer
          expr.to_s
        when nil
          "null"
        when String
          "\"#{expr}\""
        when Array
          "[#{expr.map { |e| compile_expression(e, suffix: suffix, library: library) }.join(', ')}]"
        when Date
          expr.strftime("%B %d, %Y")
        when Query::DSL::And
          t(
            suffix,
            negated ? "not_both" : "both",
            left: compile_expression(expr.lhs, suffix: suffix, library: library),
            right: compile_expression(expr.rhs, suffix: suffix, library: library)
          )
        when Query::DSL::Or
          t(
            suffix,
            negated ? "neither" : "either",
            left: compile_expression(expr.lhs, suffix: suffix, library: library),
            right: compile_expression(expr.rhs, suffix: suffix, library: library)
          )
        when Query::DSL::Not
          compile_expression(expr.expr, negated: true, suffix: suffix, library: library)
        when Query::DSL::Eq
          if expr.rhs.nil?
            key = negated ? "is_not_empty" : "is_empty"
            t(
              suffix,
              key,
              noun: compile_expression(expr.lhs, suffix: suffix, library: library)
            )
          else
            key = negated ? "does_not_equal" : "equals"
            t(
              suffix,
              key,
              left: compile_expression(expr.lhs, suffix: suffix, library: library),
              right: compile_expression(T.cast(expr.rhs, Query::DSL::ValueExpr), suffix: suffix, library: library)
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

          t(
            suffix,
            operator,
            left: compile_expression(expr.lhs, suffix: suffix, library: library),
            right: compile_expression(expr.rhs, suffix: suffix, library: library)
          )
        when Query::DSL::OneOf
          t(
            suffix,
            negated ? "not_one_of" : "one_of",
            left: compile_expression(expr.member, suffix: suffix, library: library),
            right: compile_expression(expr.set, suffix: suffix, library: library)
          )
        when Query::DSL::Contains
          t(
            suffix,
            negated ? "does_not_contain" : "contains",
            left: compile_expression(expr.lhs, suffix: suffix, library: library),
            right: compile_expression(expr.rhs, suffix: suffix, library: library)
          )
        when Query::DSL::MatchesRegex
          t(
            suffix,
            negated ? "does_not_match" : "matches",
            left: compile_expression(expr.lhs, suffix: suffix, library: library),
            right: compile_expression(expr.rhs, suffix: suffix, library: library)
          )
        when Query::DSL::Rel
          expr.name.reverse.map do |noun|
            t(
              suffix,
              "genitive",
              noun: t(suffix, "attributes.#{noun}")
            )
          end.join(" ")
        when Query::DSL::Attr
          if expr.target.name == [:self]
            t(
              suffix,
              "own_attribute",
              name: t(suffix, "attributes.#{expr.name}")
            )
          else
            t(
              suffix,
              "attribute",
              name: t(suffix, "attributes.#{expr.name}"),
              owner: compile_expression(expr.target, suffix: suffix, library: library)
            )
          end
        when Query::DSL::Var
          t(
            suffix,
            "variable",
            name: t(suffix, "attributes.#{expr.name}")
          )
        when Query::DSL::Call
          found = library.call(expr.name, expr.arguments)
          raise ArgumentError, "The library function #{expr.name} errored" unless found

          compile_expression(found, suffix: suffix, library: library)
        else
          T.absurd(expr)
        end
      end

      sig { params(suffix: T.nilable(String), key: String, kwargs: String).returns(String) }
      def self.t(suffix, key, **kwargs)
        I18n.t(
          suffix.nil? ? "fql.#{key}" : "fql.#{key}_#{suffix}",
          **T.unsafe(kwargs)
        )
      end
    end
  end
end
