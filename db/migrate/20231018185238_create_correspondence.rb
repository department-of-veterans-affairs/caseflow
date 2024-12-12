class CreateCorrespondence < ActiveRecord::Migration[6.1]
  def change
    create_table :correspondences do |t|
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"

      t.uuid :uuid, comment: "Unique identifier"
      t.datetime :portal_entry_date, comment: "Time when correspondence is created in Caseflow"
      t.string :source_type, comment: "An information identifier we get from CMP"
      t.integer :package_document_type_id, comment: "Represents entire CMP package document type"
      t.string :cmp_packet_number, comment: "Included in CMP mail package"

      t.integer :cmp_queue_id, index: true, foreign_key: true, comment: "Foreign key to CMP queues table"

      t.datetime :va_date_of_receipt, comment: "Date package delivered"
      t.bigint :veteran_id, index: true, foreign_key: true, comment: "Foreign key to veterans table"
      t.text :notes, comment: "Comes from CMP; can be updated by user"

      t.integer :correspondence_type_id, index: true, foreign_key: true, foreign_key:{to_table: :correspondence_types}, comment: "Foreign key for correspondence_types table"

      t.bigint :assigned_by_id, index: true, foreign_key: true, foreign_key:{to_table: :users}, comment: "Foreign key to users table"
      t.bigint :updated_by_id, index: true, foreign_key: true, foreign_key:{to_table: :users}, comment: "Foreign key to users table"

    end
  end
end
