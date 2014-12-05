require 'hashr'

module FactoryInspector
  class FactoryCall
    attr_reader :factory, :stack, :strategy

    def initialize(factory:, stack:, strategy:)
      @factory = factory
      @stack = stack
      @strategy = strategy
    end

    def printable_stack
      @stack.reverse.join(' -> ')
    end

    def build?
      @strategy == :build
    end

    def create?
      @strategy == :create
    end

    def ==(other)
      self.class == other.class &&
        factory == other.factory &&
        stack == other.stack &&
        strategy == other.strategy
    end
    alias_method :eql?, :==

    def hash
      [@factory, @stack, @strategy].hash
    end

    def to_s
      ":#{factory}##{strategy} called by #{printable_stack}"
    end
  end
end
