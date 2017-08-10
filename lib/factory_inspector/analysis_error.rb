require 'hashr'

module FactoryInspector
  class AnalysisError < Hashr
    def printable_call_stack
      call_stack.to_a.reverse.join(' -> ')
    end
  end
end
