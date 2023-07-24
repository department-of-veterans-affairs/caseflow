class AddPexipToConferenceLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :conference_links, :pexip, :boolean
  end
end
