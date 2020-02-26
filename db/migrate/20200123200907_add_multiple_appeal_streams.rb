class AddMultipleAppealStreams < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :stream_docket_number, :string, comment: "Multiple appeals with the same docket number indicate separate appeal streams, mimicking the structure of legacy appeals."
    add_column :appeals, :stream_type, :string, comment: "When multiple appeals have the same docket number, they are differentiated by appeal stream type, depending on the work being done on each appeal."
  end
end
