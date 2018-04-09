class AddAppealDocketToRampRefilings < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_refilings, :appeal_docket, :string
  end
end
