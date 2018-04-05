class AddCertificationV2Fields < ActiveRecord::Migration[5.1]
  def change
    # POA info fetched from BGS
    add_column :certifications, :bgs_representative_type, :string
    add_column :certifications, :bgs_representative_name, :string

    # POA info fetched from VACOLS
    add_column :certifications, :vacols_representative_type, :string
    add_column :certifications, :vacols_representative_name, :string

    # Representative type from user input.
    add_column :certifications, :representative_type, :string
    add_column :certifications, :representative_name, :string

    add_column :certifications, :hearing_change_doc_found_in_vbms, :boolean
    add_column :certifications, :form9_type, :string

    # The hearing preference that we fetch from VACOLS.
    add_column :certifications, :vacols_hearing_preference, :string

    # The hearing preference that the user confirms.
    add_column :certifications, :hearing_preference, :string
  end
end
