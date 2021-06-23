class AddUnrecognizedAppellantTables < Caseflow::Migration
  def disable_ddl_transaction
    false
  end

  def change
    create_table :unrecognized_party_details, comment: "For an appellant or POA, name and contact details for an unrecognized person or organization" do |t|
      t.string :party_type, null: false, comment: "The type of this party. Allowed values: person, organization"
      t.string :name, null: false, comment: "Name of organization, or first name or mononym of person"
      t.string :middle_name
      t.string :last_name
      t.string :suffix
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :address_line_3
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.string :country, null: false
      t.string :phone_number
      t.string :email_address
      t.timestamps null: false
    end

    create_table :unrecognized_appellants, comment: "Unrecognized non-veteran appellants" do |t|
      t.string :relationship, null: false, comment: "Relationship to veteran. Allowed values: attorney, child, spouse, other"
      t.string :poa_participant_id, comment: "Identifier of the appellant's POA, if they have a CorpDB participant_id"

      t.references :claimant, foreign_key: true, null: false, comment: "The OtherClaimant record associating this appellant to a DecisionReview"
      t.references :unrecognized_party_detail, foreign_key: true, comment: "Contact details"

      # override index name because the default is over the 63-char limit
      t.references :unrecognized_power_of_attorney,
                   foreign_key: {to_table: :unrecognized_party_details},
                   index: { name: :index_unrecognized_appellants_on_power_of_attorney_id },
                   comment: "Appellant's POA, if they aren't in CorpDB."

      t.timestamps null: false
    end
  end
end
