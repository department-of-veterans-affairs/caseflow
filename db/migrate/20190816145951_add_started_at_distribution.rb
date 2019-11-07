class AddStartedAtDistribution < ActiveRecord::Migration[5.1]
  def change
    add_column :distributions, :started_at, :datetime, comment: "when the Distribution job commenced"
    add_column :distributions, :errored_at, :datetime, comment: "when the Distribution job suffered an error"
  end
end
