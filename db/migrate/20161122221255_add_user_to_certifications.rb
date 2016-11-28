class AddUserToCertifications < ActiveRecord::Migration
  def change
    add_reference :certifications, :user, index: true, foreign_key: true
  end
end
