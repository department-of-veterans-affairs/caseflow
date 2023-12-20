class AddMoreCachedUserAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :stitle, :string, limit: 16, comment: "VACOLS cached_user_attributes.stitle"
    add_column :users, :smemgrp, :string, limit: 8, comment: "VACOLS cached_user_attributes.smemgrp"
  end
end
