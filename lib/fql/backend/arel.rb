# typed: strict
require "active_record"
module FQL
  module Backend
    class Arel
      extend T::Sig

      A = ::Arel::Nodes
      PlainValue = T.type_alias { T.any(String, Integer, Date, NilClass, T::Array[Query::DSL::Primitive]) }
      Attribute = T.type_alias { T.any(::Arel::Attribute, A::True, A::False) }
      Table = T.type_alias { T.any(::Arel::Table, A::TableAlias) }

      sig { params(model: T.class_of(ActiveRecord::Base), vars: T::Hash[Symbol, T.untyped], library: Library).void }
      def initialize(model, vars: {}, library: Library.empty)
        @model = model
        @arel_table = T.let(model.arel_table, ::Arel::Table)
        @vars = vars
        @library = library
        @joins = T.let([], T::Array[A::Join])
      end

      sig do
        params(
          model: T.class_of(ActiveRecord::Base),
          expr: Query::DSL::Root,
          vars: T::Hash[Symbol, T.untyped],
          library: Library
        ).returns(ActiveRecord::Relation)
      end
      def self.compile(model, expr, vars: {}, library: Library.empty)
        new(model, vars: vars, library: library).compile(expr)
      end

      sig { params(expr: Query::DSL::Root).returns(ActiveRecord::Relation) }
      def compile(expr)
        where_clause = compile_expression(expr)
        joins.reduce(model) do |acc, join|
          acc.joins(join.join_sources)
        end.where(where_clause).distinct
      end

      sig do
        params(
          expr: T.any(Query::DSL::Expr, NilClass, T::Array[Query::DSL::Primitive])
        ).returns(T.any(A::Node, PlainValue, Table, Attribute))
      end
      def compile_expression(expr)
        case expr
        when true, false
          expr ? A::True.new : A::False.new
        when nil
          nil
        when Integer, String, Date
          expr
        when Array                                                                                                                                             
          expr.map { |e| compile_expression(e) }
        when Query::DSL::And
          T.cast(compile_expression(expr.lhs), A::Node).and(T.cast(compile_expression(expr.rhs), A::Node))
        when Query::DSL::Or
          T.cast(compile_expression(expr.lhs), A::Node).or(T.cast(compile_expression(expr.rhs), A::Node))
        when Query::DSL::Not
          T.cast(compile_expression(expr.expr), A::Node).not
        when Query::DSL::Eq
          rhs = compile_expression(expr.rhs)
          if rhs.is_a?(Array)
            T.cast(compile_expression(expr.lhs), Attribute).in(rhs)
          else
            T.cast(compile_expression(expr.lhs), Attribute).eq(rhs) 
          end
        when Query::DSL::Gt
          T.cast(compile_expression(expr.lhs), Attribute).gt(compile_expression(expr.rhs))
        when Query::DSL::Gte
          T.cast(compile_expression(expr.lhs), Attribute).gteq(compile_expression(expr.rhs))
        when Query::DSL::Lt
          T.cast(compile_expression(expr.lhs), Attribute).lt(compile_expression(expr.rhs))
        when Query::DSL::Lte
          T.cast(compile_expression(expr.lhs), Attribute).lteq(compile_expression(expr.rhs))
        when Query::DSL::OneOf
          T.cast(compile_expression(expr.member), Attribute).in(compile_expression(expr.set))
        when Query::DSL::Contains
          T.cast(compile_expression(expr.lhs), Attribute).matches("%#{compile_expression(expr.rhs)}%")
        when Query::DSL::MatchesRegex
          T.cast(compile_expression(expr.lhs), Attribute).matches_regexp(compile_expression(expr.rhs))
        when Query::DSL::Rel
          if expr.name == [:self]
            arel_table
          else
            result = expr.name.reduce({ joins: [], model: model, aliased_relation: nil }) do |state, relation_name|
              arel_table = state[:model].arel_table
              assoc = state[:model].reflect_on_association(relation_name)
              raise "model #{state[:model].name} has no association #{relation_name}" if assoc.nil?

              new_aliased_relation = A::TableAlias.new(::Arel.sql(assoc.table_name), relation_name)

              {
                joins: state[:joins] + [
                  arel_table
                                       .join(new_aliased_relation)
                                       .on(
                                         (state[:aliased_relation] || arel_table)[assoc.join_foreign_key]
                                            .eq(new_aliased_relation[assoc.join_primary_key])
                                       )
                ],
                model: assoc.class_name.constantize,
                aliased_relation: new_aliased_relation
              }
            end

            joins.concat(result[:joins])

            result[:aliased_relation]
          end
        when Query::DSL::Var
          vars.fetch(expr.name)
        when Query::DSL::Call
          found = library.call(expr.name, expr.arguments)
          raise ArgumentError, "The library function #{expr.name} errored" unless found

          compile_expression(found)
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

      sig { returns(Library) }
      attr_reader :library
    end
  end
end
