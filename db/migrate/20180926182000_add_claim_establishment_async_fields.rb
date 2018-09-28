class AddClaimEstablishmentAsyncFields < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.connection.execute "SET statement_timeout = 1800000" # 30 minutes

    [:ramp_elections, :ramp_refilings, :higher_level_reviews, :supplemental_claims].each do |tbl|
      add_column tbl, :establishment_attempted_at, :datetime
      add_column tbl, :establishment_error, :string
    end

    add_column :request_issues_updates, :attempted_at, :datetime
    add_column :request_issues_updates, :submitted_at, :datetime
    add_column :request_issues_updates, :error, :string

  ensure
    ActiveRecord::Base.connection.execute "SET statement_timeout = 30000" # 30 seconds
  end
end
