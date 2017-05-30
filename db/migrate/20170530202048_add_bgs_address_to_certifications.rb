class AddBgsAddressToCertifications < ActiveRecord::Migration
  def change
    add_column :certifications, :bgs_address_line_1, :string
    add_column :certifications, :bgs_address_line_2, :string
    add_column :certifications, :bgs_address_line_3, :string
    add_column :certifications, :bgs_city, :string
    add_column :certifications, :bgs_country, :string
    add_column :certifications, :bgs_state, :string
    add_column :certifications, :bgs_zip, :string
  end
end


