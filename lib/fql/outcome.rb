# typed: strict

module FQL
  class Outcome
    extend T::Sig
    extend T::Generic

    Elem = type_member

    sig do
      type_parameters(:T)
        .params(value: T.type_parameter(:T))
        .returns(Outcome[T.type_parameter(:T)])
    end
    def self.ok(value)
      new(Ok.new(value: value))
    end

    sig do
      params(message: String, exception: StandardError)
        .returns(Outcome[T.untyped])
    end
    def self.error(message, exception)
      new(Error.new(message: message, exception: exception))
    end

    sig { params(obj: T.any(Ok[Elem], Error)).void }
    def initialize(obj)
      @obj = obj
    end

    sig { returns(T::Boolean) }
    def ok?
      @obj.is_a?(Ok)
    end

    sig { returns(T::Boolean) }
    def error?
      @obj.is_a?(Error)
    end

    sig { returns(T.nilable(Error)) }
    def error
      @obj if @obj.is_a?(Error)
    end

    sig { returns(T.nilable(Elem)) }
    def value
      @obj.value if @obj.is_a?(Ok)
    end

    sig do
      type_parameters(:U)
        .params(_block: T.proc.params(arg0: Elem).returns(T.type_parameter(:U)))
        .returns(Outcome[T.type_parameter(:U)])
    end
    def map(&_block)
      if @obj.is_a?(Ok)
        result = yield @obj.value
        Outcome.new(Ok.new(value: result))
      else
        self
      end
    end

    class Ok < T::Struct
      extend T::Sig
      extend T::Generic

      Elem = type_member

      const :value, Elem
    end

    class Error < T::Struct
      extend T::Sig

      const :message, String
      const :exception, StandardError
    end

    private_constant :Ok, :Error
  end
end
