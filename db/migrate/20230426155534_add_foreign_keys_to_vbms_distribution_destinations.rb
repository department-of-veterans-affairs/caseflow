class AddForeignKeysToVbmsDistributionDestinations < Caseflow::Migration
  def change
    safety_assured { add_reference(:vbms_distribution_destinations, :vbms_distribution, foreign_key: {to_table: :vbms_distrobutions} , null: false) }
    safety_assured { add_reference(:vbms_distribution_destinations, :created_by, foreign_key: { to_table: :users}, null: false) }
    safety_assured { add_reference(:vbms_distribution_destinations, :updated_by, foreign_key: { to_table: :users}) }
  end
end
