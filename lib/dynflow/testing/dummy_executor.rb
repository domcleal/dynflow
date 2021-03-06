module Dynflow
  module Testing
    class DummyExecutor
      attr_reader :world

      def initialize(world)
        @world             = world
        @events_to_process = []
      end

      def event(execution_plan_id, step_id, event, future = Future.new)
        @events_to_process << [execution_plan_id, step_id, event, future]
      end

      def progress
        events = @events_to_process.dup
        clear
        events.each do |execution_plan_id, step_id, event, future|
          future.resolve true
          world.action.execute event
        end
      end

      def clear
        @events_to_process.clear
      end
    end
  end
end
