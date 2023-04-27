class AddForeignKeysToVbmsDistributions < Caseflow::Migration
  def change
    safety_assured { add_reference(:vbms_distributions, :vbms_communication_package, foreign_key: { to_table: :vbms_communication_packages}, null: false, index: false) }
    safety_assured { add_reference(:vbms_distributions, :created_by, foreign_key: { to_table: :users}, null: false, index: false) }
    safety_assured { add_reference(:vbms_distributions, :updated_by, foreign_key: { to_table: :users}, index: false) }

    add_safe_index :vbms_distributions, :vbms_communication_package_id, algorithm: :concurrently
    add_safe_index :vbms_distributions, :created_by_id, algorithm: :concurrently
    add_safe_index :vbms_distributions, :updated_by_id, algorithm: :concurrently
  end
end
