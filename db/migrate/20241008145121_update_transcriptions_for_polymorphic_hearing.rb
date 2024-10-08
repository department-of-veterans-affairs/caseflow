class UpdateTranscriptionsForPolymorphicHearing < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      # Remove existing index if it exists
      if index_exists?(:transcriptions, :hearing_id, name: "index_transcriptions_on_hearing_id")
        remove_index :transcriptions, name: "index_transcriptions_on_hearing_id"
      end

      # Remove the existing hearing_id column
      remove_column :transcriptions, :hearing_id
    end

    # Add polymorphic reference named "hearing" without index
    add_reference :transcriptions, :hearing, polymorphic: true, index: false

    # Add the index concurrently
    add_index :transcriptions, [:hearing_type, :hearing_id], algorithm: :concurrently
  end

  def down
    safety_assured do
      # Remove the polymorphic reference
      remove_reference :transcriptions, :hearing, polymorphic: true, index: false

      # Add back the hearing_id column
      add_column :transcriptions, :hearing_id, :bigint, comment: "Hearing ID; use as FK to hearings"

      # Add back the index on the hearing_id column concurrently
      add_index :transcriptions, :hearing_id, name: "index_transcriptions_on_hearing_id", algorithm: :concurrently
    end
  end
end
