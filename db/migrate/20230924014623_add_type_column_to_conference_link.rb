class AddTypeColumnToConferenceLink < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_column :conference_links, :type, :string, comment: "Pexip or Webex conference link"

    add_index :conference_links, :type, algorithm: :concurrently
  end
end
