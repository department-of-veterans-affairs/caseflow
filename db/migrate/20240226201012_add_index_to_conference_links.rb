class AddIndexToConferenceLinks < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_index :conference_links, [:hearing_id, :hearing_type], algorithm: :concurrently
  end
end
