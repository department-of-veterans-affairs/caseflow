# frozen_string_literal: true

class CreateMembershipRequests < Caseflow::Migration
  def change
    create_table :membership_requests do |t|
      t.integer :requested_by, index: true, comment: "The requestor for this membership"
      t.references :organization, comment: "The organization that the membership request is asking to join"
      t.string :status, null: false, default: "assigned", comment: "The status of the membership request at any given point of time"
      t.integer :decided_by, null: true, comment: "The user who decides the membership_request"
      t.datetime :decided_at, comment: "The time when the membership request was decided at"

      t.timestamps # rails defaults created_at, updated_at timestamps
    end
  end
end
