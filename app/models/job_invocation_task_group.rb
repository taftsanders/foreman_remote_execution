class JobInvocationTaskGroup < ::ForemanTasks::TaskGroup

  has_one :job_invocation, :foreign_key => :task_group_id

  alias_method :associated_resource, :job_invocation

  def resource_name
    N_('Job Invocation')
  end

end
