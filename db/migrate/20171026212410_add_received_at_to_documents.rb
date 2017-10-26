class AddReceivedAtToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :received_at, :datetime
  end
end
