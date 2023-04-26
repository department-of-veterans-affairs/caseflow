class AddForeignKeysToVbmsDistributionDestinations < Caseflow::Migration
  def change
    add_reference :vbms_distribution_destinations, :vbms_distributions, foreign_key: true, null: false
    add_reference :vbms_distribution_destinations, :created_by, foreign_key: { to_table: :users}, null: false
    add_reference :vbms_distribution_destinations, :updated_by, foreign_key: { to_table: :users}
  end
end
