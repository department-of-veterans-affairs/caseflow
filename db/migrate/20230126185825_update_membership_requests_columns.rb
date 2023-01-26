class UpdateMembershipRequestsColumns < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :membership_requests, :requested_by, :integer }
    safety_assured { remove_column :membership_requests, :decided_by, :integer }

    add_column :membership_requests, :requested_by_id, :integer, index: true, comment: "The requestor for this membership"
    add_column :membership_requests, :decided_by_id, :integer, null: true, comment: "The user who decides the membership_request"
  end
end
