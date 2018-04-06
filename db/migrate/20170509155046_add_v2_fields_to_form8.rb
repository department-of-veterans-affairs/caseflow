class AddV2FieldsToForm8 < ActiveRecord::Migration[5.1]
  def change
    add_column :form8s, :hearing_preference, :string
    add_column :form8s, :nod_date, :date
    add_column :form8s, :form9_date, :date
  end
end
