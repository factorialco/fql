# typed: ignore
require 'zeitwerk'
require 'sorbet-runtime'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "fql" => "FQL",
  "dsl" => "DSL"
)
loader.setup

module FQL
end
