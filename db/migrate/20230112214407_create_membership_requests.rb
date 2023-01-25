# frozen_string_literal: true

class CreateMembershipRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :membership_requests do |t|
      t.references :user
      t.references :organization
      t.string :status, null: false
      t.integer :closed_by_user_id, null: true
      t.datetime :closed_at

      t.timestamps
    end
  end
end
