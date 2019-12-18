class AddMoreCachedUserAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_user_attributes, :stitle, :string, length: 16
    add_column :cached_user_attributes, :smemgrp, :string, length: 8
  end
end
