class AddJobInvocationTaskGroup < ActiveRecord::Migration
  def change
    alter_table :job_invocations |t|
      t.integer :task_group_id, index: true
    end
  end
end
