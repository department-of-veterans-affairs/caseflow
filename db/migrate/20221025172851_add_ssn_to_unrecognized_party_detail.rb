class AddSsnToUnrecognizedPartyDetail < Caseflow::Migration
  def change
    unless ActiveRecord::Base.connection.column_exists?(:unrecognized_party_details, :ssn)
      add_column :unrecognized_party_details, :ssn, :string, comment: "PII. Social Security Number"
    end
  end
end
