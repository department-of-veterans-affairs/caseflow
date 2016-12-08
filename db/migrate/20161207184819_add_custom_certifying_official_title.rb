class AddCustomCertifyingOfficialTitle < ActiveRecord::Migration
  def change
    add_column :form8s, :custom_certifying_official_title, :string
  end
end
