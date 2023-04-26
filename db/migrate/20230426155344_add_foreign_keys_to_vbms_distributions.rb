class AddForeignKeysToVbmsDistributions < Caseflow::Migration
  def change
     safety_assured { add_reference(:vbms_distributions, :vbms_communication_package, foreign_key: { to_table: :vbms_communication_packages}, null: false) }
     safety_assured { add_reference(:vbms_distributions, :created_by, foreign_key: { to_table: :users}, null: false) }
     safety_assured { add_reference(:vbms_distributions, :updated_by, foreign_key: { to_table: :users} ) }
  end
end
