class AddAppellantTzAndRepresentativeTzToVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :appellant_tz, :string, :limit => 50, comment: "Stores appellant timezone"
    add_column :virtual_hearings, :representative_tz, :string, :limit => 50, comment: "Stores representative timezone"
  end
end
