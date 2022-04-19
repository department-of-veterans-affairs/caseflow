class AddConferenceLinksTable < ActiveRecord::Migration[5.2]
  def change
      create_table :conference_links do |t|
          t.belongs_to :hearing_day
          t.string     :alias
          t.string     :alias_with_host
          t.boolean    :conference_deleted, default: false, null: false
          t.integer    :conference_id
          t.datetime   :created_at, null: false 
          t.bigint     :created_by_id, null: false
          t.bigint     :hearing_day_id, null: false
          t.string     :host_hearing_link
          t.integer    :host_pin
          t.string     :host_pin_long, limit: 8
          t.datetime   :updated_at
          t.bigint     :updated_by_id
      end

      add_foreign_key "conference_links", "users", column: "created_by_id", validate: false
      add_foreign_key "conference_links", "users", column: "updated_by_id", validate: false
      add_foreign_key "conference_links", "hearing_days", column: "hearing_day_id", validate: false
  end
end