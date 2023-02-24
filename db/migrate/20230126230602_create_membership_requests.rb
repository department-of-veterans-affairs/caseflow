class CreateMembershipRequests < Caseflow::Migration
  def change
    create_table :membership_requests do |t|
      t.references :organization, foreign_key: true, comment: "The organization that the membership request is asking to join"

      t.references :requestor, foreign_key: { to_table: :users }, comment: "The User that is requesting access to the organization"
      t.references :decider, foreign_key: { to_table: :users }, index: false, null: true, comment: "The user who decides the status of the membership request"

      t.string :note, null: true, comment: "A note that provides additional context from the requestor about their request for access to the organization"
      t.datetime :decided_at, comment: "The date and time when the deider user made a decision about the membership request"
      t.string :status, null: false, default: "assigned", comment: "The status of the membership request at any given point of time"

      t.timestamps
    end
  end
end
