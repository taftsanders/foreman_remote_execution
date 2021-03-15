module ForemanRemoteExecutionCore
  module Actions
    class Pull < ::ForemanTasksCore::ShareableAction
      execution_plan_hooks.use :wipe_job!, :on => :stopped

      def run(event = nil)
        case event
        when nil
          init_run
          suspend
        when ::ForemanTasksCore::Runner::ExternalEvent
          process_external_event(event)
          suspend unless done?
        end
      end

      def finalize
        error! 'Script execution failed' if failed_run?
      end

      def wipe_job!(_execution_plan)
        JobStorage.remove(host_identification, execution_plan_id, self.id)
      end

      def payload
        input[:script]
      end

      def rescue_strategy_for_self
        Dynflow::Action::Rescue::Fail
      end

      private

      def init_run
        output[:result] = []
        JobStorage.put(host_identification, execution_plan_id, self.id)
        mqtt_notify if mqtt_enabled?
      end

      # Event structure:
      # { "output": String
      # , "exit_code": nil | Integer
      # }
      #
      # If exit_code is non-nil, the action finishes.
      def process_external_event(event)
        data = event.data
        exit_code = data['exit_code']
        chunk = ForemanTasksCore::ContinuousOutput.format_output(data['output'], 'stdout')
        output[:result] << chunk
        output[:exit_status] = exit_code if exit_code
      end

      def done?
        output[:exit_status]
      end

      def mqtt_notify
        # TODO:
      end

      def mqtt_enabled?
        # TODO:
        false
      end

      def failed_run?
        output[:exit_status] != 0
      end

      def host_identification
        # TODO: This needs to be changed
        input[:hostname]
      end
    end
  end
end
