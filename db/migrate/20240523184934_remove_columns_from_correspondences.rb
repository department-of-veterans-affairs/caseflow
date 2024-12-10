class RemoveColumnsFromCorrespondences < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      remove_column :correspondences, :portal_entry_date, :datetime
      remove_column :correspondences, :source_type, :string
      remove_column :correspondences, :cmp_packet_number, :bigint
      remove_column :correspondences, :cmp_queue_id, :integer
      remove_column :correspondences, :package_document_type_id, :integer
    end
  end
end
