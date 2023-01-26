# frozen_string_literal: true

class CreateMembershipRequests < Caseflow::Migration
  def change
    create_table :membership_requests do |t|
      t.integer :requested_by, index: true
      t.references :organization
      t.string :status, null: false, default: "assigned"
      t.integer :decided_by, null: true
      t.datetime :decided_at

      t.timestamps
    end
  end
end
