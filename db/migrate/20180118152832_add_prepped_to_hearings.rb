class AddPreppedToHearings < ActiveRecord::Migration
  def change
    add_column :hearings, :prepped, :boolean
  end
end
