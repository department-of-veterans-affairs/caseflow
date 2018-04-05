class AddCertificationSignAndCertifyFields < ActiveRecord::Migration[5.1]
  def change
    add_column :certifications, :certifying_office, :string
    add_column :certifications, :certifying_username, :string
    add_column :certifications, :certifying_official_name, :string
    add_column :certifications, :certifying_official_title, :string
    add_column :certifications, :certification_date, :string
  end
end
