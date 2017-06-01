class AddBgsAddressToCertifications < ActiveRecord::Migration
  def change
    add_column :certifications, :bgs_rep_address_line_1, :string
    add_column :certifications, :bgs_rep_address_line_2, :string
    add_column :certifications, :bgs_rep_address_line_3, :string
    add_column :certifications, :bgs_rep_city, :string
    add_column :certifications, :bgs_rep_country, :string
    add_column :certifications, :bgs_rep_state, :string
    add_column :certifications, :bgs_rep_zip, :string
  end
end


