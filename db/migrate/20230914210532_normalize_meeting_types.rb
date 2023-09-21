# frozen_string_literal: true

class NormalizeMeetingTypes < Caseflow::Migration
  disable_ddl_transaction!

  def change
    create_table :meeting_types do |table|
      table.integer :service_name, comment: "Pexip or Webex Instant Connect", default: 0
    end

    # Create polymorhpic association for other classes to tap into
    add_reference :meeting_types, :conferenceable, polymorphic: true, index: false
    add_index :meeting_types,
              [:conferenceable_type, :conferenceable_id],
              algorithm: :concurrently,
              name: "conferenceable_association_idx"

    # Remove existing columns
    safety_assured do
      remove_column :virtual_hearings, :meeting_type, :string
      remove_column :conference_links, :meeting_type, :string
      remove_column :users, :meeting_type, :string
    end
  end
end
