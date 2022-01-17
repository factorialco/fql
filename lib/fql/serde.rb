# typed: strict

module FQL
  module Serde
    extend T::Sig
    extend T::Helpers
    extend T::Generic

    interface!

    Input = type_member
    Output = type_member

    sig do
      abstract
      .params(input: Input)
      .returns(Query::DSL::BoolExpr)
    end
    def deserialize(input); end

    sig do
      abstract
      .params(input: Query::DSL::BoolExpr)
      .returns(Output)
    end
    def serialize(input); end
  end
end
