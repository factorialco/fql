# typed: false
require "spec_helper"

RSpec.describe FQL::Serde::JSON do
  F = FQL::Query::DSL unless defined?(F)

  subject { described_class.new }

  matcher :roundtrip do
    match do |expression|
      serialized = subject.serialize(expression)
      subject.serialize(
        subject.deserialize(
          serialized
        ).unwrap!
      ) == serialized
    end
    failure_message do |expression|
      "expected #{expression.inspect} to roundtrip, but it did not (it serialized to '#{subject.serialize(expression)}')"
    end
  end

  it "fails on malformed input" do
    expect(subject.deserialize({}).error?).to be(true)
  end

  it "roundtrips And" do
    expect(F.and(F.eq(true, false), F.eq(false, true))).to roundtrip
  end

  it "roundtrips Or" do
    expect(F.or(F.eq(true, false), F.eq(false, true))).to roundtrip
  end

  it "roundtrips Not" do
    expect(F.not(F.eq(true, false))).to roundtrip
  end

  it "roundtrips Eq" do
    expect(F.eq(true, nil)).to roundtrip
  end

  it "roundtrips Gt" do
    expect(F.gt(F.attr(F.rel(:self), :name), 3)).to roundtrip
  end

  it "roundtrips Gte" do
    expect(F.gte(F.attr(F.rel(:self), :name), 3)).to roundtrip
  end

  it "roundtrips Lt" do
    expect(F.lt(F.attr(F.rel(:self), :name), 3)).to roundtrip
  end

  it "roundtrips Lte" do
    expect(F.lte(F.attr(F.rel(:self), :name), 3)).to roundtrip
  end

  it "roundtrips Var" do
    expect(F.lte(F.attr(F.rel(:self), :name), F.var(:number))).to roundtrip
  end

  it "roundtrips Contains" do
    expect(F.contains(F.attr(F.rel(:self), :name), "hello")).to roundtrip
  end

  it "roundtrips MatchesRegex" do
    expect(F.matches_regex(F.attr(F.rel(:self), :name), "hello")).to roundtrip
  end

  it "roundtrips a complex query" do
    expect(
      F.or(
        F.eq(
          F.attr(
            F.rel(:location),
            :country
          ),
          "es"
        ),
        F.gt(
          F.attr(
            F.rel(:salary),
            :amount
          ),
          F.var(:threshold)
        )
      )
    ).to roundtrip
  end
end
