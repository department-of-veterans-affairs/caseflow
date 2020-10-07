class CreateEndProductUpdate < ActiveRecord::Migration[5.2]
  def change
    create_table :end_product_updates, comment: "Updates the claim label for end products established from Caseflow" do |t|
      t.integer :user_id, comment: "The ID of the user who makes an end product update."
      t.bigint :end_product_establishment_id, comment: "The end product establishment id used to track the end product being updated"
      t.bigint :original_decision_review_id, null: false, comment: "The original ID of the decision review that this end product update belongs to; has a non-nil value only if a new decision_review was created."
      t.string :original_decision_review_type, null: false, comment: "The original decision review type that this end product update belongs to"
      t.string :status, null: false, comment: "Status after an attempt to update the end product; expected values: 'success', 'error', ..."
      t.string :error, null: false, comment: "The error message captured from BGS if the end product update failed."
      t.string :original_code, comment: "The original end product code before the update was submitted"
      t.string :new_code, comment: "The new end product code the user wants to update to."
      t.integer :active_request_issue_ids, null: false, array: true, default: [], comment: "A list of active request issue IDs when a user has finished editing a decision review. Used to keep track of which request issues may have been impacted by the update."

      t.timestamps null: false
    end
  end
end
