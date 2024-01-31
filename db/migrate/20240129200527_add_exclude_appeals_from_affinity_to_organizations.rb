class AddExcludeAppealsFromAffinityToOrganizations < Caseflow::Migration
  def up
    add_column :organizations,
      :exclude_appeals_from_affinity,
      :boolean,
      :default => false,
      :null => false,
      comment: "Used to track whether a judge (team) should have their affinity appeals distributed to any available judge team even if the set amount of time has not elapsed."
  end

  def down
    remove_column :organizations, :exclude_appeals_from_affinity
  end
end
