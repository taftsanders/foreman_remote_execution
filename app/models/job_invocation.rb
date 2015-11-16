class JobInvocation < ActiveRecord::Base
  include Authorizable

  include ForemanRemoteExecution::ErrorsFlattener
  FLATTENED_ERRORS_MAPPING = { :template_invocations => lambda do |template_invocation|
                                                          _("template") + " #{template_invocation.template.name}"
                                                        end }

  belongs_to :targeting, :dependent => :destroy
  has_many :template_invocations, :inverse_of => :job_invocation, :dependent => :destroy

  validates :targeting, :presence => true
  validates :job_name, :presence => true
  validates_associated :targeting, :template_invocations

  scoped_search :on => :job_name

  delegate :bookmark, :resolved?, :to => :targeting, :allow_nil => true

  include ForemanTasks::Concerns::ActionSubject

  belongs_to :task, :class_name => 'ForemanTasks::Task'
  has_many :sub_tasks, :through => :task

  belongs_to :task_group, :class_name => 'JobInvocationTaskGroup'

  has_many :tasks, :through => :task_group

  scoped_search :on => [:job_name], :complete_value => true

  belongs_to :triggering, :class_name => 'ForemanTasks::Triggering'

  def deep_clone
    JobInvocationComposer.new.compose_from_invocation(self).job_invocation.tap do |invocation|
      invocation.task_group = JobInvocationTaskGroup.new.tap(&:save!)
      invocation.template_invocations = self.template_invocations.map(&:deep_clone)
      invocation.save!
    end
  end

  def to_action_input
    { :id => id, :name => job_name }
  end

  def template_invocation_tasks
    sub_tasks.for_action_types('Actions::RemoteExecution::RunHostJob')
  end

  def failed_template_invocation_tasks
    template_invocation_tasks.where(:result => 'warning')
  end

  def failed_host_ids
    locks_for_resource(failed_template_invocation_tasks, 'Host::Managed').map(&:resource_id)
  end

  def failed_hosts
    locks_for_resource(failed_template_invocation_tasks, 'Host::Managed').map(&:resource)
  end

  def locks_for_resource(tasks, resource_type)
    tasks.map { |task| task.locks.where(:resource_type => resource_type).first }.compact
  end

  def total_hosts_count
    if targeting.resolved?
      targeting.hosts.count
    else
      _('N/A')
    end
  end

  def template_invocation_for_host(host)
    providers = available_providers(host)
    providers.each do |provider|
      template_invocations.each do |template_invocation|
        if template_invocation.template.provider_type == provider
          return template_invocation
        end
      end
    end
  end

  # TODO: determine from the host and job_invocation details
  def available_providers(host)
    return RemoteExecutionProvider.provider_names
  end

  def sub_task_for_host(host)
    sub_tasks.joins(:locks).where("#{ForemanTasks::Lock.table_name}.resource_type" => 'Host::Managed', "#{ForemanTasks::Lock.table_name}.resource_id" => host.id).first
  end
end
