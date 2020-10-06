class CreateEndProductUpdate < ActiveRecord::Migration[5.2]
  def change
    create_table :end_product_updates, comment: "Keeps track of the request issues to update the claim label in Caseflow" do |t|
      t.integer :user_id, comment: "The ID of the user who makes an end product update."
      t.bigint :end_product_establishment_id, comment: "This is end product establishment id that Caseflow uses to keep track of the end product that is being updated"
      t.bigint :original_decision_review_id, comment: "The original ID of the decision review that this request issue belongs to"
      t.string :status, comment: "This shows whether the attempt to update the end product was successful or whether it resulted in an error"
      t.string :error, comment: "The error captured if end product update has failed."
      t.string :original_code, comment: "This is an original code before the update was submitted (just in case someone edits an end product twice)"
      t.string :new_code, comment: "This is a new end product code the user wants to update to."
      t.integer :active_request_issue_ids, null: false, comment: "An array of the active request issue IDs when a user has finished editing a decision review. Used to keep track of which request issues may have been impacted by the update.", array: true

      t.timestamps null: false
    end
  end
end
