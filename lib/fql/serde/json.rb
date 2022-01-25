# typed: strict
require "json"

module FQL
  module Serde
    class JSON
      extend T::Sig
      extend T::Generic

      sig { params(input: String).returns(Query::DSL::BoolExpr) }
      def deserialize(input)
        m = T.let(::JSON.parse(input), T::Hash[String, T.untyped])
        T.cast(parse_expression(m), Query::DSL::BoolExpr)
      end

      sig { params(expr: Query::DSL::BoolExpr).returns(String) }
      def serialize(expr)
        ::JSON.generate(serialize_expression(expr))
      end

      sig do
        params(
          expr: T.nilable(T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr))
        ).returns(
          T.any(
            T::Hash[Symbol, T.untyped],
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
        when Query::DSL::And
          { op: "and", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs) }
        when Query::DSL::Or
          { op: "or", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs) }
        when Query::DSL::Not
          { op: "not", expr: serialize_expression(expr.expr) }
        when Query::DSL::Eq, Query::DSL::Gt, Query::DSL::Gte, Query::DSL::Lt, Query::DSL::Lte
          operator = case expr
                     when Query::DSL::Eq then "eq"
                     when Query::DSL::Gt then "gt"
                     when Query::DSL::Gte then "gte"
                     when Query::DSL::Lt then "lt"
                     when Query::DSL::Lte then "lte"
                     end
          { op: operator, lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs) }
        when Query::DSL::Contains
          { op: "contains", lhs: serialize_expression(expr.lhs), rhs: serialize_expression(expr.rhs) }
        when Query::DSL::Rel
          { op: "rel", name: expr.name }
        when Query::DSL::Attr
          { op: "attr", target: serialize_expression(expr.target), name: expr.name }
        when Query::DSL::Var
          { op: "var", name: expr.name }
        when Query::DSL::MatchesRegex
          { op: "matches_regex", lhs: serialize_expression(expr.lhs), rhs: expr.rhs }
        else
          T.absurd(expr)
        end
      end

      private

      sig do
        params(expr: T.any(T::Hash[String, T.untyped], T::Boolean, Integer, String,
                           Date, NilClass)).returns(T.any(Query::DSL::BoolExpr, Query::DSL::ValueExpr, NilClass))
      end
      def parse_expression(expr)
        if expr.is_a?(Hash) && expr.key?("op")
          case expr["op"]
          when "and"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::BoolExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::BoolExpr)
            Query::DSL::And.new(lhs: lhs, rhs: rhs)
          when "eq"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), T.nilable(Query::DSL::ValueExpr))
            Query::DSL::Eq.new(lhs: lhs, rhs: rhs)
          when "or"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::BoolExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::BoolExpr)
            Query::DSL::Or.new(lhs: lhs, rhs: rhs)
          when "not"
            expr = T.cast(parse_expression(expr["expr"]), Query::DSL::BoolExpr)
            Query::DSL::Not.new(expr: expr)
          when "gt"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::ValueExpr)
            Query::DSL::Gt.new(lhs: lhs, rhs: rhs)
          when "gte"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::ValueExpr)
            Query::DSL::Gte.new(lhs: lhs, rhs: rhs)
          when "lt"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::ValueExpr)
            Query::DSL::Lt.new(lhs: lhs, rhs: rhs)
          when "lte"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            rhs = T.cast(parse_expression(expr["rhs"]), Query::DSL::ValueExpr)
            Query::DSL::Lte.new(lhs: lhs, rhs: rhs)
          when "rel"
            Query::DSL::Rel.new(name: expr["name"].map(&:to_sym))
          when "attr"
            target = T.cast(parse_expression(expr["target"]), Query::DSL::Rel)
            Query::DSL::Attr.new(target: target, name: expr["name"].to_sym)
          when "var"
            Query::DSL::Var.new(name: expr["name"].to_sym)
          when "contains"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            Query::DSL::Contains.new(lhs: lhs, rhs: expr["rhs"])
          when "matches_regex"
            lhs = T.cast(parse_expression(expr["lhs"]), Query::DSL::ValueExpr)
            Query::DSL::MatchesRegex.new(lhs: lhs, rhs: expr["rhs"])
          else
            raise "unrecognized op '#{expr['op']}'"
          end
        elsif expr.is_a?(Hash) || expr.is_a?(Array)
          # it's a primitive value
          raise "can't parse expression: #{expr}"
        else
          expr
        end
      end
    end
  end
end
