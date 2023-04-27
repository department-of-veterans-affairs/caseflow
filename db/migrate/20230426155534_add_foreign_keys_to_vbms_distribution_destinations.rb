class AddForeignKeysToVbmsDistributionDestinations < Caseflow::Migration
  def change
    safety_assured { add_reference(:vbms_distribution_destinations, :vbms_distribution, foreign_key: {to_table: :vbms_distrobutions} , null: false, index: false) }
    safety_assured { add_reference(:vbms_distribution_destinations, :created_by, foreign_key: { to_table: :users}, null: false, index: false) }
    safety_assured { add_reference(:vbms_distribution_destinations, :updated_by, foreign_key: { to_table: :users}, index: false) }

    add_safe_index :vbms_distribution_destinations, :vbms_distribution_id, algorithm: :concurrently
    add_safe_index :vbms_distribution_destinations, :created_by_id, algorithm: :concurrently
    add_safe_index :vbms_distribution_destinations, :updated_by_id, algorithm: :concurrently
  end
end
