class AddCoHostLinkToConferenceLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :conference_links, :co_host_link, :string
  end
end
