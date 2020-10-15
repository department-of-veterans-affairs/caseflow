class CreateEndProductUpdate < Caseflow::Migration
  disable_ddl_transaction!

  def change
    create_table :end_product_updates, comment: "Updates the claim label for end products established from Caseflow" do |t|
      t.string :status, comment: "Status after an attempt to update the end product; expected values: 'success', 'error', ..."
      t.string :error, comment: "The error message captured from BGS if the end product update failed."
      t.string :original_code, comment: "The original end product code before the update was submitted."
      t.string :new_code, comment: "The new end product code the user wants to update to."
      t.bigint :active_request_issue_ids, null: false, array: true, default: [], comment: "A list of active request issue IDs when a user has finished editing a decision review. Used to keep track of which request issues may have been impacted by the update."

      t.timestamps null: false
      t.references :user, null: false, foreign_key: true, comment: "The ID of the user who makes an end product update."
      t.references :end_product_establishment, null: false, foreign_key: true, comment: "The end product establishment id used to track the end product being updated."
      t.references :original_decision_review, null: true, polymorphic: true, index: false, comment: "The original decision review that this end product update belongs to; has a non-nil value only if a new decision_review was created."
    end

     add_index :end_product_updates, [:original_decision_review_type, :original_decision_review_id], algorithm: :concurrently, name: "index_epupdates_on_decision_review_type_and_decision_review_id"

     change_column_comment :end_product_updates, :original_decision_review_type, "The original decision review type that this end product update belongs to"
  end
end
