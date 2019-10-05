class CreateJobNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :job_notes do |t|
      t.belongs_to :job, polymorphic: true, null: false, comment: "The job to which the note applies"
      t.belongs_to :user, null: false, comment: "The user who created the note"
      t.timestamps null: false, comment: "Default created_at/updated_at"
      t.text :note, null: false, comment: "The note"
      t.boolean :send_to_intake_user, default: false, comment: "Should the note trigger a message to the job intake user"
    end
  end
end
