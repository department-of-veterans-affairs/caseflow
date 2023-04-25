class CreateVbmsDistrobutionDestinations < Caseflow::Migration
  def change
    create_table :vbms_distrobution_destinations do |t|
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
      t.timestamp :created_at, null: false
      t.timestamp :updated_at
    end
  end
end
