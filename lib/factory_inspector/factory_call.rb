require 'hashr'

module FactoryInspector
  class FactoryCall
    attr_reader :factory, :stack, :strategy, :time

    def initialize(factory:, stack:, strategy:, time:)
      @factory = factory
      @stack = stack
      @strategy = strategy
      @time = time
    end

    def printable_stack
      @printable_stack ||= @stack.join('->')
    end

    def build?
      @strategy == :build
    end

    def create?
      @strategy == :create
    end

    def called_by?(other)
      return false if @stack.one?
      (other.stack & @stack).size == other.stack.size
    end

    def eql?(other)
      if other.equal?(self)
        return true
      elsif !self.class.equal?(other.class)
        return false
      end
      other.factory == @factory &&
        other.strategy == @strategy &&
        other.stack == @stack
    end

    def hash
      [@factory, @stack, @strategy].hash
    end

    def description
      ":#{@factory}##{@strategy}"
    end

    def to_s
      "#{description} due to #{printable_stack}"
    end
  end
end
