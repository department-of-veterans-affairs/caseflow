class AddBirthdateToUnrecognizedParty < Caseflow::Migration
  def change
    add_column :unrecognized_party_details, :date_of_birth, :date,
      comment: "PII"
  end
end
