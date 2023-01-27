class CreateMembershipRequests < Caseflow::Migration
  def change
    create_table :membership_requests do |t|
      t.references :organization, foreign_key: true, comment: "The organization that the membership request is asking to join"

      t.references :requestor, foreign_key: { to_table: :users }, comment: "The requestor for this membership"
      t.references :decider, foreign_key: { to_table: :users }, index: false, null: true, comment: "The user who decides the membership_request"

      t.datetime :decided_at, comment: "The time when the membership request was decided at"
      t.string :status, null: false, default: "assigned", comment: "The status of the membership request at any given point of time"

      t.timestamps
    end
  end
end
