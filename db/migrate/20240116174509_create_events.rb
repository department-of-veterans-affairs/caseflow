class CreateEvents < Caseflow::Migration
  def change
    create_table :events, comment: "Stores events from the Appeals-Consumer application that are processed by Caseflow" do |t|
      t.string :reference_id, null: false, comment: "Id of Event Record being referenced within the Appeals Consumer Application"
      t.string :type, null: false, comment: "Type of Event (e.g. DecisionReviewCreatedEvent)"
      t.timestamp :created_at, null: false, comment: "Automatic timestamp when row was created"
      t.timestamp :updated_at, null: false, comment: "Automatic timestamp whenever the record changes"
      t.timestamp :completed_at, comment: "Timestamp of when event was successfully completed"
      t.string :error, comment: "Error message captured during a failed event"
    end
  end
end
