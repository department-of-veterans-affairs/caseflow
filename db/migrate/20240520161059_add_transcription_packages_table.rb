class AddTranscriptionPackagesTable < ActiveRecord::Migration[6.1]
  def change
    create_table :transcription_packages do |t|
      t.string     :aws_link_zip, comment: "Link of where the file is in AWS S3 (transcription_text) for the return work order"
      t.string     :aws_link_work_order, comment: "Link of where the file is in AWS S3 (transcription_text) for the return work order"
      t.bigint     :created_by_id, comment: "The user who created the transcription record"
      t.date       :expected_return_date, comment: "Expected date when transcription would be returned by the transcriber"
      t.string     :status, comment: "Status of the package, could be one of nil, 'Successful Upload (AWS), Successful Upload (BOX), Failed Upload (BOX), Successful Retrieval (BOX), Failed Retrieval (BOX)'"
      t.datetime   :returned_at, null: false, comment: "When the Contractor returns their completed Work Order excel file"
      t.string     :task_number, comment: "Number associated with transcription, use as FK to transcriptions"
      t.bigint     :updated_by_id, comment: "The user who most recently updated the transcription file"
      t.timestamps
      t.index ["task_number"], name: "index_transcription_packages_on_task_number"
    end
  end
end
