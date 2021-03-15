module ForemanRemoteExecutionCore
  module TaskLauncher
    class Pull < ::ForemanTasksCore::TaskLauncher::Batch
      private

      def child_launcher(parent)
        require 'pry'; binding.pry
        launcher = super
        launcher.options[:action_class_override] = ForemanRemoteExecutionCore::Actions::Pull
        require 'pry'; binding.pry
        launcher
      end
    end
  end
end
