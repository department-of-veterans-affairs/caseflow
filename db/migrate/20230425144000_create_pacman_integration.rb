class CreatePacmanIntegration < Caseflow::Migration
  def change
    create_table :vbms_communication_packages do |t|
      t.string :file_number
      t.bigint :document_referenced, default: [], array: true
      t.string :status
      t.string :comm_package_name, null: false
      t.timestamps

      t.references :vbms_uploaded_document, index: true, foreign_key: { to_table: :vbms_uploaded_documents }
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
    end

    create_table :vbms_distributions do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :participant_id
      t.string :poa_code, null: false
      t.string :claimant_station_of_jurisdiction, null: false
      t.timestamps

      t.references :vbms_communication_package, index: true, foreign_key: { to_table: :vbms_communication_packages }
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }

    end

    create_table :vbms_distribution_destinations do |t|
      t.string :type, null: false
      t.string :address_line_1, null: false
      t.string :address_line_2, null: false
      t.string :address_line_3, null: false
      t.string :address_line_4
      t.string :address_line_5
      t.string :address_line_6
      t.boolean :treat_line_2_as_addressee, null: false
      t.boolean :treat_line_3_as_addressee
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country_name, null: false
      t.string :country_code, null: false
      t.string :email_address, null: false
      t.string :phone_number, null: false
      t.timestamps

      t.references :vbms_distribution, index: true, foreign_key: { to_table: :vbms_distributions }
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
    end
  end
end
