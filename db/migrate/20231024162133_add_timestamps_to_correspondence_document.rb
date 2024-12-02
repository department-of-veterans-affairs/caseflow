class AddTimestampsToCorrespondenceDocument < ActiveRecord::Migration[6.1]
  def change
    add_column :correspondence_documents, :created_at, :datetime, null: false, comment: "Date and Time of creation."
    add_column :correspondence_documents, :updated_at, :datetime, null: false, comment: "Date and Time of last update."
  end
end
