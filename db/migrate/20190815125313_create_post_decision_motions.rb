class CreatePostDecisionMotions < ActiveRecord::Migration[5.1]
  def change
    create_table :post_decision_motions, comment: "Stores the disposition and associated task of post-decisional motions handled by the Litigation Support Team: Motion for Reconsideration, Motion to Vacate, and Clear and Unmistakeable Error." do |t|
      t.string :disposition, comment: "Possible options are Grant, Deny, Withdraw, and Dismiss"
      t.references :task, foreign_key: true

      t.timestamps
    end
  end
end
