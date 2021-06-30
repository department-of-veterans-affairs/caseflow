class AddPiiCommentOnUnrecognizedPartyDetails < Caseflow::Migration
  def up
    change_column_comment :unrecognized_party_details, :address_line_1, "PII"
    change_column_comment :unrecognized_party_details, :address_line_2, "PII"
    change_column_comment :unrecognized_party_details, :address_line_3, "PII"
    change_column_comment :unrecognized_party_details, :email_address, "PII"
    change_column_comment :unrecognized_party_details, :last_name, "PII"
    change_column_comment :unrecognized_party_details, :middle_name, "PII"
    change_column_comment :unrecognized_party_details, :name, "PII"
    change_column_comment :unrecognized_party_details, :phone_number, "PII"
    change_column_comment :unrecognized_party_details, :suffix, "PII"
  end

  def down
    change_column_comment :unrecognized_party_details, :address_line_1, nil
    change_column_comment :unrecognized_party_details, :address_line_2, nil
    change_column_comment :unrecognized_party_details, :address_line_3, nil
    change_column_comment :unrecognized_party_details, :email_address, nil
    change_column_comment :unrecognized_party_details, :last_name, nil
    change_column_comment :unrecognized_party_details, :middle_name, nil
    change_column_comment :unrecognized_party_details, :name, nil
    change_column_comment :unrecognized_party_details, :phone_number, nil
    change_column_comment :unrecognized_party_details, :suffix, nil
  end
end
