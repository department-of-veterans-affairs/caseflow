class Appeal < ApplicationRecord
  self.ignored_columns = ["last_submitted_at"]
end

class RenameLastSubmittedAtPt3 < ActiveRecord::Migration[5.1]
  def the_tables
    [:appeals, :higher_level_reviews, :supplemental_claims]
  end

  def up
    safety_assured do
      the_tables.each do |tbl|
        remove_column tbl, :last_submitted_at
      end
    end
  end

  def down
    safety_assured do
      the_tables.each do |tbl|
        add_column tbl, :last_submitted_at, :datetime
        execute "UPDATE #{tbl} SET last_submitted_at=establishment_last_submitted_at"
      end
    end
  end
end
