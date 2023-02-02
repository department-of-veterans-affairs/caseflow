class AddNoteToMembershipRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :membership_requests, :note, :string
  end
end
