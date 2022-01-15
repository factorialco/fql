require 'benchmark'

n = 50_000

Benchmark.bm do |benchmark|
  benchmark.report("instance_eval") do
    x = 8
    code = 'self + 5'
    n.times do
      x.instance_eval(code)
    end
  end

  benchmark.report("compile + eval proc") do
    x = 8
    code = 'proc { |x| x + 5 }'
    f = RubyVM::InstructionSequence.compile(code).eval
    n.times do
      f.call(x)
    end
  end
end
