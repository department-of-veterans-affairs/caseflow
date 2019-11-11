# frozen_string_literal: true

class AddBrokenColumnToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :broken_column, :strong, comment: "This line works unless a typo somehow sneaks in."
  end
end
