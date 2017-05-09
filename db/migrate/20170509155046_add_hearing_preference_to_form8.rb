class AddHearingPreferenceToForm8 < ActiveRecord::Migration
  def change
    add_column :form8s, :hearing_preference, :string
  end
end
