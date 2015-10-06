class AddJobInvocationTaskGroup < ActiveRecord::Migration
  def up
    add_column :job_invocations, :task_group_id, :integer, :index => true
  end

  def down
    remove_column :job_invocations, :task_group_id
  end
end
