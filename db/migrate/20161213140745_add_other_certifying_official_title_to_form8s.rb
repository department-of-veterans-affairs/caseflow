class AddOtherCertifyingOfficialTitleToForm8s < ActiveRecord::Migration
  def change
    add_column :form8s, :certifying_official_title_specify_other, :string
  end
end
