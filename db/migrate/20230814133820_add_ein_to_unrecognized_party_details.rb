class AddEinToUnrecognizedPartyDetails < Caseflow::Migration
  def change
    add_column :unrecognized_party_details, :ein, :string, comment: "PII. Employer Identification Number"
  end
end
