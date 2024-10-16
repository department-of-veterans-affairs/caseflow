class AddReturnDateToTranscriptionsTable < ActiveRecord::Migration[6.1]
  def change
    add_column :transcriptions, :return_date, :date, comment: "Date when the contractor returned their work product, box.com upload date"
  end
end
