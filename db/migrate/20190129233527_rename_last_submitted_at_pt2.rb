class RenameLastSubmittedAtPt2 < ActiveRecord::Migration[5.1]
  def the_tables
    [:appeals, :higher_level_reviews, :supplemental_claims]
  end

  def up
    safety_assured do
      the_tables.each do |tbl|
        execute "UPDATE #{tbl} SET establishment_last_submitted_at=last_submitted_at"
      end
    end
  end

  def down
  end
end
