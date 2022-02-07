# typed: strict

module FQL
  class Validation
    extend T::Sig

    class Result < T::Struct
      extend T::Sig

      const :errors, T::Array[String]

      sig { returns(T::Boolean) }
      def valid?
        errors.empty?
      end
    end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::BoolExpr).returns(Result) }
    def self.validate(model, expr)
      new(model, expr).validate
    end

    sig { params(model: T.class_of(ActiveRecord::Base), expr: Query::DSL::BoolExpr).void }
    def initialize(model, expr)
      @model = model
      @expr = expr
      @errors = T.let([], T::Array[String])
    end

    sig { returns(Result) }
    def validate
      validate_expression!(expr)
      Result.new(errors: errors)
    end

    private

    sig do
      params(expr: T.nilable(T.any(Query::DSL::BoolExpr,
                                   Query::DSL::ValueExpr))).returns(T.nilable(T.class_of(ActiveRecord::Base)))
    end
    def validate_expression!(expr)
      case expr
      when Query::DSL::Not
        validate_expression!(expr.expr)
        nil
      when Query::DSL::Gt,
           Query::DSL::Gte,
           Query::DSL::Lt,
           Query::DSL::Lte,
           Query::DSL::Eq,
           Query::DSL::Contains,
           Query::DSL::MatchesRegex,
           Query::DSL::And,
           Query::DSL::Or
        validate_expression!(expr.lhs)
        validate_expression!(expr.rhs)
        nil
      when Query::DSL::OneOf
        validate_expression!(expr.member)
        validate_expression!(expr.set)
        nil
      when Query::DSL::Rel
        if expr.name == [:self]
          model
        else
          expr.name.reduce(model) do |current_model, relation_name|
            next(nil) if current_model.nil?

            assoc = current_model.reflect_on_association(relation_name)
            if assoc.nil?
              errors.append("model #{current_model} has no association #{relation_name}")
              nil
            else
              assoc.class_name.constantize
            end
          end
        end
      when Query::DSL::Attr
        target = validate_expression!(expr.target)
        if target&.columns&.none? { |column| column.name == expr.name.to_s }
          errors.append("#{target} does not contain attribute #{expr.name}")
        end
        nil
      end
    end

    sig { returns(T.class_of(ActiveRecord::Base)) }
    attr_reader :model

    sig { returns(Query::DSL::BoolExpr) }
    attr_reader :expr

    sig { returns(T::Array[String]) }
    attr_reader :errors
  end
end
