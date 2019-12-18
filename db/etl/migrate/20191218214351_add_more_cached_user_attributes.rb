class AddMoreCachedUserAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :stitle, :string, limit: 16
    add_column :users, :smemgrp, :string, limit: 8
  end
end
