class CreateEndProductUpdate < ActiveRecord::Migration[5.2]
  def change
    create_table :end_product_updates, comment: "Keeps track of the request issues to update the claim label in Caseflow" do |t|
      t.integer :user_id, comment: "The ID of the user who edits a decision review."
      t.bigint :end_product_establishment_id, comment: "The ID of the End Product Establishment created for this request issue after user has finished editing a decision review."
      t.bigint :original_decision_review_id, comment: "The original ID of the decision review that this request issue belongs to"
      t.string :status, comment: "Shows success or error text upon completion of editing a decision review."
      t.string :error, comment: "The error captured for the most recent attempt after end product update has failed."
      t.string :original_code, comment: "The original end product code after an intake has been established."
      t.string :new_code, comment: "This is the new end product code after a user has finished editing a decision review and establishing an end product."
      t.integer :active_request_issue_ids, null: false, comment: "An array of the active request issue IDs after a user has finished editing a decision review. Used with before_request_issue_ids to determine appropriate actions (such as which contentions need to be added).", array: true

      t.timestamps null: false
    end
  end
end
