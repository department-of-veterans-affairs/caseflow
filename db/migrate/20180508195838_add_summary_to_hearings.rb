class AddSummaryToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :summary, :text
  end
end
