class AddEstablishedAtToRampRefilings < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_refilings, :established_at, :datetime
  end
end
