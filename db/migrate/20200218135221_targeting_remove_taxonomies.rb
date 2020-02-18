class TargetingAddTaxonomies < ActiveRecord::Migration[5.2]
  def up
    remove_column(:targetings, :organization_id)
    remove_column(:targetings, :location_id)
  end

  def down
    add_column(:targetings, :organization_id, :integer)
    add_column(:targetings, :location_id, :integer)
  end

end
