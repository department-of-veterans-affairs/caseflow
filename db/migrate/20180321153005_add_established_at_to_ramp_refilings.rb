class AddEstablishedAtToRampRefilings < ActiveRecord::Migration
  def change
    add_column :ramp_refilings, :established_at, :datetime
  end
end
