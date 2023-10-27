# frozen_string_literal: true

class CreateCorrespondenceTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :correspondence_types do |t|
      t.string :name
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
