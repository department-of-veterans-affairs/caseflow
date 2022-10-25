class AddSsnToUnrecognizedPartyDetail < Caseflow::Migration
  def change
    add_column :unrecognized_party_details, :ssn, :string, comment: "PII. Social Security Number"
  end
end
