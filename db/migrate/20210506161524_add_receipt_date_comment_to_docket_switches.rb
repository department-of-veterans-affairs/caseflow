class AddReceiptDateCommentToDocketSwitches < ActiveRecord::Migration[5.2]
  def change
    change_column_comment(:docket_switches, :receipt_date, "Date the board receives the NOD with request for docket switch; entered by user performing docket switch")
  end
end
