# typed: false

module FQL
  class Library
    extend T::Sig

    class << self
      extend T::Sig

      sig do
        params(
          name: Symbol,
          body: T.proc.params(args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr)
        ).void
      end
      def function(name, &body)
        @functions ||= {}
        @functions[name] = body
      end

      sig { returns(T::Hash[Symbol, T.proc.params(args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr)]) }
      def functions
        @functions || {}
      end
    end

    sig { returns(Library) }
    def self.empty
      Library.new
    end

    sig { params(name: Symbol, args: T::Array[Query::DSL::Expr]).returns(Query::DSL::Expr) }
    def call(name, args)
      found = self.class.functions[name] or
        raise NotImplementedError, "#{name.inspect} is not implemented in the library. Available functions: {#{self.class.functions.keys.map(&:inspect).join(', ')}}"

      found.call(*args)
    end

    sig { returns(String) }
    def inspect
      "<#{self.class.name} { #{self.class.functions.keys.map(&:inspect).join(', ')} }>"
    end
  end
end
