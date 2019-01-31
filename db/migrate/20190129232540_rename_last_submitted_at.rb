class RenameLastSubmittedAt < ActiveRecord::Migration[5.1]
  def the_tables
    [:appeals, :higher_level_reviews, :supplemental_claims]
  end

  def up
    the_tables.each do |tbl|
      add_column tbl, :establishment_last_submitted_at, :datetime
    end
  end

  def down
    the_tables.each do |tbl|
      remove_column tbl, :establishment_last_submitted_at
    end
  end
end
