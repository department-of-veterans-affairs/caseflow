class CreateHearingDispositionChanges < Caseflow::Migration
  def change
    create_table :hearing_disposition_changes do |t|
      t.string :hearing_type
      t.datetime :created_at
      t.datetime :updated_at
      t.text :previous_disposition
      t.text :new_disposition
      t.text :change_reason
      t.text :change_justification
      t.references :user, foreign_key: true
    end

    add_reference :hearing_disposition_changes,
                  :created_by,
                  index: true,
                  foreign_key: { to_table: :users },
                  comment: "The ID of the user who created the disposition change"
    add_reference :hearing_disposition_changes,
                  :updated_by,
                  index: true,
                  foreign_key: { to_table: :users },
                  comment: "The ID of the user who most recently updated the virtual hearing"
  end
end
