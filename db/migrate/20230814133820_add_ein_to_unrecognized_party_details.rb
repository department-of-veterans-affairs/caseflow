class AddEinToUnrecognizedPartyDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :unrecognized_party_details, :ein, :string, comment: "PII. Employer Identification Number"
  end
end
