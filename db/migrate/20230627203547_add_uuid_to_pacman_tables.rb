class AddUuidToPacmanTables < Caseflow::Migration
  def up
    add_column :vbms_communication_packages,
      :uuid,
      :string,
      comment: "UUID of the communication package in Package Manager (Pacman)"

    add_column :vbms_distributions,
      :uuid,
      :string,
      comment: "UUID of the distrubtion in Package Manager (Pacman)"
  end

  def down
    remove_column :vbms_communication_packages, :uuid
    remove_column :vbms_distributions, :uuid
  end
end
