class CreatePacmanIntegration < Caseflow::Migration
  def change
    create_table :vbms_communication_packages do |t|
      t.string :file_number, comment: "number associated with the documents."
      t.bigint :document_referenced, default: [], array: true
      t.string :status
      t.string :comm_package_name, null: false
      t.timestamps

      t.references :vbms_uploaded_document, index: true, foreign_key: { to_table: :vbms_uploaded_documents }
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
    end

    create_table :vbms_distributions do |t|
      t.string :recipient_type, null: false, comment: "Must be one of [person, organization, ro-colocated, System]."
      t.string :name, comment: "should only be used for non-person entity names. Not null if [recipient_type] is organization, ro-colocated, or System."
      t.string :first_name, comment: "recipient's first name. If Type is [person] then it cant be null."
      t.string :middle_name, comment: "recipient's middle name."
      t.string :last_name, comment: "recipient's last name. If Type is [person] then it cant be null."
      t.string :participant_id, comment: "recipient's participant id."
      t.string :poa_code, comment: "Can't be null if [recipient_type] is ro-colocated. The recipients POA code"
      t.string :claimant_station_of_jurisdiction, comment: "Can't be null if [recipient_type] is ro-colocated."
      t.timestamps

      t.references :vbms_communication_package, index: true, foreign_key: { to_table: :vbms_communication_packages }
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }

    end

    create_table :vbms_distribution_destinations do |t|
      t.string :destination_type, null: false, comment: "Must be 'domesticAddress', 'internationalAddress', 'militaryAddress', 'derived', 'email', or 'sms'. Cannot be 'physicalAddress'."
      t.string :address_line_1, null: false, comment: "PII. If destination_type is domestic, international, or military then Must not be null."
      t.string :address_line_2, comment: "PII. If treatLine2AsAddressee is [true] then must not be null"
      t.string :address_line_3, comment: "PII. If treatLine3AsAddressee is [true] then must not be null"
      t.string :address_line_4, comment: "PII."
      t.string :address_line_5, comment: "PII."
      t.string :address_line_6, comment: "PII."
      t.boolean :treat_line_2_as_addressee
      t.boolean :treat_line_3_as_addressee
      t.string :city, comment: "PII. If type is [domestic, international, military] then Must not be null"
      t.string :state, comment: "PII. Must be exactly two-letter ISO 3166-2 code. If destination_type is domestic or military then Must not be null"
      t.string :postal_code
      t.string :country_name
      t.string :country_code,comment: "Must be exactly two-letter ISO 3166 code."
      t.string :email_address
      t.string :phone_number, comment: "PII."
      t.timestamps

      t.references :vbms_distribution, index: true, foreign_key: { to_table: :vbms_distributions }
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
    end
  end
end
