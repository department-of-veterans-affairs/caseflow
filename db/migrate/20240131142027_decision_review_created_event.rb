class DecisionReviewCreatedEvent < ActiveRecord::Migration[5.2]
  def change
    create_table :decision_review_created_events do |t|
      t.jsonb :info, default: {}
      t.timestamps
    end

    add_index :decision_review_created_events, :info, using: :gin
  end
end
