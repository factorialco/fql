# typed: strict
require "zeitwerk"
require "sorbet-runtime"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "fql" => "FQL",
  "dsl" => "DSL",
  "json" => "JSON"
)
loader.setup

module FQL
end
