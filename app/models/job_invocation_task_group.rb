class JobInvocationTaskGroup < ::ForemanTasks::TaskGroup

  has_one :job_invocation, :foreign_key => :task_group_id

end
