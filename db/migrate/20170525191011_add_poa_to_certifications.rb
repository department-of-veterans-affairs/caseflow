class AddPoaToCertifications < ActiveRecord::Migration
  def change
    add_column :certifications, :poa_matches, :boolean
    add_column :certifications, :poa_correct_in_vacols, :boolean
    add_column :certifications, :poa_correct_in_bgs, :boolean
  end
end
