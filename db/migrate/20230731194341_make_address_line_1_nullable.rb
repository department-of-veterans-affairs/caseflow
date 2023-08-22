class MakeAddressLine1Nullable < Caseflow::Migration
  def change
    change_column_null(:vbms_distribution_destinations, :address_line_1, true)
  end
end
