module ForemanRemoteExecutionCore
  module Api
    def self.included(base)
      base.get "/jobs/:host_identifier" do |host|
        jobs = JobStorage.get(host).map do |job|
          plan = SmartProxyDynflowCore::Core.world.persistence.load_execution_plan(job.execution_plan_uuid)
          action = SmartProxyDynflowCore::Core.world.persistence.load_actions(plan, [job.action_id]).first

          { :execution_plan_uuid => job.execution_plan_uuid,
            :run_step_id => action.run_step_id,
            :action_id => job.action_id,
            :payload => action.payload
          }
        end
        jobs.to_json
      end
    end
  end
end

SmartProxyDynflowCore::Api.send(:include, ForemanRemoteExecutionCore::Api)
