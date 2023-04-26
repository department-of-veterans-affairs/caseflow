class AddForeignKeysToVbmsDistrobutions < Caseflow::Migration
  def change
    add_reference :vbms_distributions, :vbms_communication_packages, foreign_key: true, null: false
    add_reference :vbms_distributions, :created_by, foreign_key: { to_table: :users}, null: false
    add_reference :vbms_distributions, :updated_by, foreign_key: { to_table: :users}
  end
end
