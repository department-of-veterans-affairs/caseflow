class AddMoreCachedUserAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_user_attributes, :stitle, :string, limit: 16
    add_column :cached_user_attributes, :smemgrp, :string, limit: 8
  end
end
