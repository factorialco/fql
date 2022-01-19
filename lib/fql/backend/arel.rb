# typed: strict
require "active_record"

module FQL
  module Backend
    class Arel
      extend T::Sig
      extend T::Generic

      A = ::Arel::Nodes
      PlainValue = T.type_alias { T.any(String, Integer, Date) }
      Attribute = T.type_alias { T.any(::Arel::Attribute, A::True, A::False) }
      Table = T.type_alias { T.any(::Arel::Table, A::TableAlias) }

      sig { params(model: T.class_of(ActiveRecord::Base), vars: T::Hash[Symbol, T.untyped]).void }
      def initialize(model, vars={})
        @model = model
        @arel_table = T.let(model.arel_table, ::Arel::Table)
        @vars = vars
        @joins = T.let([], T::Array[A::Join])
      end

      sig do
        params(
          model: T.class_of(ActiveRecord::Base),
          expr: Query::DSL::BoolExpr,
          vars: T::Hash[Symbol, T.untyped]
        ).returns(ActiveRecord::Relation)
      end
      def self.compile(model, expr, vars={})
        new(model, vars).compile(expr)
      end

      sig { params(expr: Query::DSL::BoolExpr).returns(ActiveRecord::Relation) }
      def compile(expr)
        where_clause = compile_expression(expr)
        joins.reduce(model) do |acc, join|
          acc.joins(join.join_sources)
        end.where(where_clause)
      end

      sig do
        params(expr: T.any(Query::DSL::BoolExpr,
                           Query::DSL::ValueExpr)).returns(T.any(A::Node, PlainValue, Table, Attribute))
      end
      def compile_expression(expr)
        case expr
        when true, false
          expr ? A::True.new : A::False.new
        when Integer, String, Date
          expr
        when Query::DSL::And
          T.cast(compile_expression(expr.lhs), A::Node).and(T.cast(compile_expression(expr.rhs), A::Node))
        when Query::DSL::Or
          T.cast(compile_expression(expr.lhs), A::Node).or(T.cast(compile_expression(expr.rhs), A::Node))
        when Query::DSL::Not
          T.cast(compile_expression(expr.expr), A::Node).not
        when Query::DSL::Eq
          T.cast(compile_expression(expr.lhs), Attribute).eq(compile_expression(expr.rhs))
        when Query::DSL::Gt
          T.cast(compile_expression(expr.lhs), Attribute).gt(compile_expression(expr.rhs))
        when Query::DSL::Gte
          T.cast(compile_expression(expr.lhs), Attribute).gteq(compile_expression(expr.rhs))
        when Query::DSL::Lt
          T.cast(compile_expression(expr.lhs), Attribute).lt(compile_expression(expr.rhs))
        when Query::DSL::Lte
          T.cast(compile_expression(expr.lhs), Attribute).lteq(compile_expression(expr.rhs))
        when Query::DSL::Contains
          T.cast(compile_expression(expr.lhs), Attribute).matches("%#{compile_expression(expr.rhs)}%")
        when Query::DSL::MatchesRegex
          T.cast(compile_expression(expr.lhs), Attribute).matches_regexp(compile_expression(expr.rhs))
        when Query::DSL::Rel
          if expr.name == [:self]
            arel_table
          else
            result = expr.name.reduce({ the_joins: [], model: model, aliased_relation: nil }) do |state, relation_name|
              arel_table = state[:model].arel_table
              assoc = model.reflect_on_association(relation_name)
              aliased_relation = A::TableAlias.new(::Arel.sql(assoc.table_name), relation_name)

              {
                the_joins: state[:the_joins] + [
                  arel_table
                                               .join(aliased_relation)
                                               .on(
                                                 arel_table[assoc.join_foreign_key]
                                                   .eq(aliased_relation[assoc.join_primary_key])
                                               )
                ],
                model: assoc.class_name.constantize,
                aliased_relation: aliased_relation
              }
            end

            joins.concat(result[:the_joins])

            result[:aliased_relation]
          end
        when Query::DSL::Var
          vars.fetch(expr.name)
        when Query::DSL::Attr
          T.cast(compile_expression(expr.target), Table)[expr.name]
        else
          T.absurd(expr)
        end
      end

      private

      sig { returns(T.class_of(ActiveRecord::Base)) }
      attr_reader :model

      sig { returns(::Arel::Table) }
      attr_reader :arel_table

      sig { returns(T::Array[T.untyped]) }
      attr_reader :joins

      sig { returns(T::Hash[Symbol, T.untyped]) }
      attr_reader :vars
    end
  end
end
