# frozen_string_literal: true

class AddUniqueConstraintToOrganizationUrl < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :organizations, :url, unique: true, algorithm: :concurrently
  end
end
