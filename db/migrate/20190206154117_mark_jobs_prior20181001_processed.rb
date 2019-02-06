class MarkJobsPrior20181001Processed < ActiveRecord::Migration[5.1]
  def up
    [:higher_level_reviews, :supplemental_claims].each do |tbl|
      execute "UPDATE #{tbl} SET establishment_processed_at=establishment_submitted_at WHERE establishment_attempted_at IS NULL AND establishment_submitted_at < '2018-10-01'"
    end
  end

  def down
  end
end
