class AddTriggeringToJobInvocation < ActiveRecord::Migration
  def up
    add_column :job_invocations, :triggering_id, :integer, :index => true
  end

  def down
    remove_column :job_invocations, :triggering_id
  end
end
