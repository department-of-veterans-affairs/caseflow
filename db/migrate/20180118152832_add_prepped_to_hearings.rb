class AddPreppedToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :prepped, :boolean
  end
end
