class CreateApiViews < ActiveRecord::Migration
  def change
    create_table :api_views do |t|
      t.datetime   :created_at
      t.string     :vbms_id
      t.belongs_to :api_key, foreign_key: true
    end
  end
end
