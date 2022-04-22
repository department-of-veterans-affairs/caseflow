class AddIndexesToConferenceLinks < Caseflow::Migration
  def change 
    add_safe_index :conference_links, [:hearing_day_id], name: "index_hearing_day_id"
    add_safe_index :conference_links, [:created_by_id], name: "index_created_by_id"
    add_safe_index :conference_links, [:updated_by_id], name: "index_updated_by_id"
  end
end