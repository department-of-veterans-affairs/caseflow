# frozen_string_literal: true

class CreateCorrespondenceAutoAssignmentLevers < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    create_table :correspondence_auto_assignment_levers do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.integer :value, null: false
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

    add_safe_index :correspondence_auto_assignment_levers, :name, unique: true
  end
end
