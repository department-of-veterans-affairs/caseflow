class AddUserToCertifications < ActiveRecord::Migration[5.1]
  def change
    add_reference :certifications, :user, index: true, foreign_key: true
  end
end
