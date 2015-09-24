class AddJobInvocationTaskGroup < ActiveRecord::Migration
  def change
    alter_table :foreman_tasks_task_groups do |t|
      t.integer :job_invocation_id, index: true
    end
  end
end
