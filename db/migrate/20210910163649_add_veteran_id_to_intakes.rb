class AddVeteranIdToIntakes < Caseflow::Migration
  def change
    add_column :intakes, :veteran_id, :bigint, comment: "The ID of the veteran associated with this intake"
  end
end
