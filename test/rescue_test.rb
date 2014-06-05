require_relative 'test_helper'

module Dynflow
  module RescueTest
    describe 'on error' do

      Example = Support::RescueExample

      include WorldInstance

      def execute(*args)
        plan = world.plan(*args)
        raise plan.errors.first if plan.error?
        world.execute(plan.id).value
      end

      let :rescued_plan do
        execution_plan.rescue_from_error.value
      end

      describe 'of simple skippable action in run phase' do

        let :execution_plan do
          execute(Example::ActionWithSkip, 1, :error_on_run)
        end

        it 'suggests skipping the action' do
          execution_plan.rescue_strategy.must_equal Action::Rescue::Skip
        end

        it 'skips the action and continues' do
          rescued_plan.state.must_equal :stopped
          rescued_plan.result.must_equal :warning
          rescued_plan.entry_action.output[:message].
              must_equal "skipped because some error as you wish"
        end

      end

      describe 'of simple skippable action in finalize phase' do

        let :execution_plan do
          execute(Example::ActionWithSkip, 1, :error_on_finalize)
        end

        it 'suggests skipping the action' do
          execution_plan.rescue_strategy.must_equal Action::Rescue::Skip
        end

        it 'skips the action and continues' do
          rescued_plan.state.must_equal :stopped
          rescued_plan.result.must_equal :warning
          rescued_plan.entry_action.output[:message].must_equal "Been here"
        end

      end

      describe 'of complex action with skips in run phase' do

        let :execution_plan do
          execute(Example::ComplexActionWithSkip, :error_on_run)
        end

        it 'suggests skipping the action' do
          execution_plan.rescue_strategy.must_equal Action::Rescue::Skip
        end

        it 'skips the action and continues' do
          rescued_plan.state.must_equal :stopped
          rescued_plan.result.must_equal :warning
          skipped_action = rescued_plan.actions.find do |action|
            action.run_step && action.run_step.state == :skipped
          end
          skipped_action.output[:message].must_equal "skipped because some error as you wish"
        end

      end

      describe 'of complex action with skips in finalize phase' do

        let :execution_plan do
          execute(Example::ComplexActionWithSkip, :error_on_finalize)
        end

        it 'suggests skipping the action' do
          execution_plan.rescue_strategy.must_equal Action::Rescue::Skip
        end

        it 'skips the action and continues' do
          rescued_plan.state.must_equal :stopped
          rescued_plan.result.must_equal :warning
          skipped_action = rescued_plan.actions.find do |action|
            action.steps.find { |step| step && step.state == :skipped }
          end
          skipped_action.output[:message].must_equal "Been here"
        end

      end

      describe 'of complex action without skips' do

        let :execution_plan do
          execute(Example::ComplexActionWithoutSkip, :error_on_run)
        end

        it 'suggests pausing the plan' do
          execution_plan.rescue_strategy.must_equal Action::Rescue::Pause
        end

        it 'fails rescuing' do
          lambda { rescued_plan }.must_raise Errors::RescueError
        end

      end

      describe 'auto rescue' do

        def world
          @world ||= WorldInstance.create_world(auto_rescue: true)
        end

        describe 'of plan with skips' do

           let :execution_plan do
             execute(Example::ComplexActionWithSkip, :error_on_run)
           end

           it 'skips the action and continues automatically' do
             execution_plan.state.must_equal :stopped
             execution_plan.result.must_equal :warning
           end

        end

        describe 'of plan faild on auto-rescue' do

           let :execution_plan do
             execute(Example::ActionWithSkip, 1, :error_on_skip)
           end

           it 'tryied to rescue only once' do
             execution_plan.state.must_equal :paused
             execution_plan.result.must_equal :error
           end

        end

        describe 'of plan without skips' do

          let :execution_plan do
             execute(Example::ComplexActionWithoutSkip, :error_on_run)
           end

           it 'skips the action and continues automatically' do
             execution_plan.state.must_equal :paused
             execution_plan.result.must_equal :error
           end

        end

      end
    end
  end
end
