class AddEstablishedAtToRampElections < ActiveRecord::Migration
  def change
    add_column :ramp_elections, :established_at, :datetime
  end
end
