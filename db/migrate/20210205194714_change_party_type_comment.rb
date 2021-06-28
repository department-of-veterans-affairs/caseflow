class ChangePartyTypeComment < Caseflow::Migration
  def up
    change_column_comment :unrecognized_party_details, :party_type, "The type of this party. Allowed values: individual, organization"
  end

  def down
    change_column_comment :unrecognized_party_details, :party_type, "The type of this party. Allowed values: person, organization"
  end
end
