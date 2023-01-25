# frozen_string_literal: true

class CreateMembershipRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :membership_requests do |t|
      t.integer :requested_by, index: true
      t.references :organization
      t.string :status, null: false, default: 'assigned'
      t.integer :closed_by, null: true
      t.datetime :closed_at

      t.timestamps
    end
  end
end
