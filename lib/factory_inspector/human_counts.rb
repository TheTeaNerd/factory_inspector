module FactoryInspector
  module HumanCounts
    def human_count(number)
      case number
      when 1 then 'once'
      when 2 then 'twice'
      else "#{number} times"
      end
    end
  end
end
