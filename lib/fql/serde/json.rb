# typed: strict
require "json"
require "active_support/core_ext/hash/keys"

module FQL
  module Serde
    class JSON
      extend T::Sig
      extend T::Generic

      sig { params(input: T::Hash[T.any(String, Symbol), T.untyped]).returns(Outcome[Query::DSL::BoolExpr]) }
      def deserialize(input)
        parse_expression(input.deep_symbolize_keys).map { |parsed| T.cast(parsed, Query::DSL::BoolExpr) }
      end

      sig { params(expr: Query::DSL::BoolExpr).returns(T::Hash[Symbol, T.untyped]) }
      def serialize(expr)
        T.cast(serialize_expression(expr), T::Hash[Symbol, T.untyped])
      end

      sig do
        params(
          expr: T.nilable(T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr))
        ).returns(
          T.any(
            T::Hash[Symbol, T.untyped],
            T::Array[T.untyped],
            T::Boolean,
            String,
            Integer,
            Date,
            NilClass
          )
        )
      end
      def serialize_expression(expr)
        case expr
        when nil, true, false, Integer, String
          expr
        when Date
          expr.to_s
        when Array
          expr.map { |e| serialize_expression(e) }
        when Query::DSL::And
          { op: "and", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs), metadata: expr.metadata }
        when Query::DSL::Or
          { op: "or", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs), metadata: expr.metadata }
        when Query::DSL::Not
          { op: "not", expr: serialize_expression(expr.expr), metadata: expr.metadata }
        when Query::DSL::Eq, Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
                     when Query::DSL::Eq then "eq"
                     when Query::DSL::Gt then "gt"
                     when Query::DSL::Gte then "gte"
                     when Query::DSL::Lt then "lt"
                     when Query::DSL::Lte then "lte"
                     end
          { op: operator, lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs), metadata: expr.metadata }
        when Query::DSL::OneOf
          { op: "one_of", member: serialize_expression(expr.member), set: serialize_expression(expr.set), metadata: expr.metadata }
        when Query::DSL::Contains
          { op: "contains", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs), metadata: expr.metadata }
        when Query::DSL::Rel
          { op: "rel", name: expr.name.map(&:to_s), metadata: expr.metadata }
        when Query::DSL::Attr
          { op: "attr", target: serialize_expression(expr.target), name: expr.name.to_s, metadata: expr.metadata }
        when Query::DSL::Var
          { op: "var", name: expr.name.to_s, metadata: expr.metadata }
        when Query::DSL::Call
          { op: "call", name: expr.name.to_s, arguments: expr.arguments.map { |arg| serialize_expression(arg) }, metadata: expr.metadata }
        when Query::DSL::MatchesRegex
          { op: "matches_regex", lhs: serialize_expression(expr.lhs), rhs: expr.rhs.to_s, metadata: expr.metadata }
        else
          T.absurd(expr)
        end
      end

      private

      sig do
        params(expr: T.any(T::Hash[Symbol, T.untyped], T::Boolean, Integer, String,
                           Date, NilClass)).returns(Outcome[T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr,
                                                                  NilClass)])
      end
      def parse_expression(expr)
        if expr.is_a?(Hash) && expr.key?(:op)
          case expr[:op]
          when "and"
            parse_expression(expr[:lhs]).bind do |lhs|
              parse_expression(expr[:rhs]).map do |rhs|
                lhs = T.cast(lhs, Query::DSL::BoolExpr)
                rhs = T.cast(rhs, Query::DSL::BoolExpr)
                Query::DSL::And.new(lhs: lhs, rhs: rhs, metadata: expr[:metadata])
              end
            end
          when "eq"
            parse_expression(expr[:lhs]).bind do |lhs|
              parse_expression(expr[:rhs]).map do |rhs|
                lhs = T.cast(lhs, Query::DSL::ValueExpr)
                rhs = T.cast(rhs, T.nilable(Query::DSL::ValueExpr))
                Query::DSL::Eq.new(lhs: lhs, rhs: rhs, metadata: expr[:metadata])
              end
            end
          when "or"
            parse_expression(expr[:lhs]).bind do |lhs|
              parse_expression(expr[:rhs]).map do |rhs|
                lhs = T.cast(lhs, Query::DSL::BoolExpr)
                rhs = T.cast(rhs, Query::DSL::BoolExpr)
                Query::DSL::Or.new(lhs: lhs, rhs: rhs, metadata: expr[:metadata])
              end
            end
          when "not"
            parse_expression(expr[:expr]).map do |expression|
              expression = T.cast(expression, Query::DSL::BoolExpr)
              Query::DSL::Not.new(expr: expression, metadata: expr[:metadata])
            end
          when "gt", "gte", "lt", "lte"
            parse_expression(expr[:lhs]).bind do |lhs|
              parse_expression(expr[:rhs]).map do |rhs|
                lhs = T.cast(lhs, Query::DSL::ValueExpr)
                rhs = T.cast(rhs, Query::DSL::ValueExpr)
                T.must(case expr[:op]
                       when "gt"
                         Query::DSL::Gt
                       when "gte"
                         Query::DSL::Gte
                       when "lt"
                         Query::DSL::Lt
                       when "lte"
                         Query::DSL::Lte
                       end).new(lhs: lhs, rhs: rhs, metadata: expr[:metadata])
              end
            end
          when "rel"
            Outcome.ok(Query::DSL::Rel.new(name: expr[:name].map(&:to_sym), metadata: expr[:metadata]))
          when "attr"
            parse_expression(expr[:target]).map do |target|
              target = T.cast(target, Query::DSL::Rel)
              Query::DSL::Attr.new(target: target, name: expr[:name].to_sym, metadata: expr[:metadata])
            end
          when "var"
            Outcome.ok(Query::DSL::Var.new(name: expr[:name].to_sym, metadata: expr[:metadata]))
          when "call"
            args = expr[:arguments].map { |arg| parse_expression(arg) }
            errors = args.select(&:error?).map do |errored|
              errored.error.message
            end
            if errors.any?
              Outcome.error(errors.join(", "))
            else
              parsed = args.map(&:value)
              Outcome.ok(Query::DSL::Call.new(name: expr[:name].to_sym, arguments: parsed, metadata: expr[:metadata]))
            end
          when "one_of"
            parse_expression(expr[:member]).map do |member|
              member = T.cast(member, Query::DSL::ValueExpr)
              Query::DSL::OneOf.new(member: member, set: expr[:set], metadata: expr[:metadata])
            end
          when "contains"
            parse_expression(expr[:lhs]).map do |lhs|
              lhs = T.cast(lhs, Query::DSL::ValueExpr)
              Query::DSL::Contains.new(lhs: lhs, rhs: expr[:rhs], metadata: expr[:metadata])
            end
          when "matches_regex"
            parse_expression(expr[:lhs]).map do |lhs|
              lhs = T.cast(lhs, Query::DSL::ValueExpr)
              Query::DSL::MatchesRegex.new(lhs: lhs, rhs: expr[:rhs], metadata: expr[:metadata])
            end
          else
            Outcome.error("unrecognized op '#{expr[:op]}'")
          end
        elsif expr.is_a?(Hash) || expr.is_a?(Array)
          # it's a primitive value
          Outcome.error("can't parse expression: #{expr}")
        else
          Outcome.ok(expr)
        end
      end
    end
  end
end
