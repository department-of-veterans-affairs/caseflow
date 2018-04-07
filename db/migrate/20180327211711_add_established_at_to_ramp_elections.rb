class AddEstablishedAtToRampElections < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_elections, :established_at, :datetime
  end
end
