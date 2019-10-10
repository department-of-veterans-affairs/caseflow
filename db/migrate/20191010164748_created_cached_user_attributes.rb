class CreatedCachedUserAttributes < ActiveRecord::Migration[5.1]
  def change
    create_table :cached_user_attributes, id: false, comment: "VACOLS cached staff table attributes" do |t|
      t.timestamps null: false
      t.string :sdomainid, length: 20, null: false
      t.string :sattyid, length: 4
      t.string :svlj, length: 1
      t.string :slogid, length: 16, null: false
      t.string :stafkey, length: 16, null: false
      t.string :sactive, length: 1, null: false
    end

    add_index :cached_user_attributes, [:sdomainid], unique: true
  end
end
