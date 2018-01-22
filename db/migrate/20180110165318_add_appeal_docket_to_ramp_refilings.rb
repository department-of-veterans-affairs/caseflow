class AddAppealDocketToRampRefilings < ActiveRecord::Migration
  def change
    add_column :ramp_refilings, :appeal_docket, :string
  end
end
