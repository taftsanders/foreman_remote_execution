require 'singleton'

module ForemanRemoteExecutionCore
  class JobStorage
    include Singleton

    Job = Struct.new(:execution_plan_uuid, :action_id)

    attr_reader :storage
    def initialize
      # Key is host identifier
      # Value is an array of jobs
      @storage = Hash.new { |h, key| h[key] = [] }
    end

    def put(key, job)
      @storage[key] << job
    end

    def get(key)
      @storage[key]
    end

    def remove(key, job)
      @storage[key].delete(job)
    end

    # Public API
    class << self
      def put(key, execution_plan_id, action_id)
        JobStorage.instance.put(key, Job.new(execution_plan_id, action_id))
      end

      def get(key)
        JobStorage.instance.get(key)
      end

      def remove(key, execution_plan_id, action_id)
        JobStorage.instance.remove(key, Job.new(execution_plan_id, action_id))
      end
    end
  end
end
