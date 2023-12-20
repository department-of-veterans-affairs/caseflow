class AddConferenceLinksTable < Caseflow::Migration
  def change
      create_table :conference_links do |t|
          t.belongs_to :hearing_day
          t.string     :alias, comment: "Alias of the conference"
          t.string     :alias_with_host, comment: "Alieas of the conference for the host"
          t.boolean    :conference_deleted, default: false, null: false, comment: "Flag to represent if a con ference has been deleted"
          t.integer    :conference_id, comment: "Id of the conference"
          t.datetime   :created_at, null: false, comment: "Date and Time of creation"
          t.bigint     :created_by_id, null: false, comment: "User id of the user who created the record. FK on User table"
          t.bigint     :hearing_day_id, null: false, comment: "The associated hearing day id"
          t.string     :host_link, comment: "Conference link generated from external conference service"
          t.integer    :host_pin, comment: "Pin for the host of the conference to get into the conference"
          t.string     :host_pin_long, limit: 8, comment: "Generated host pin stored as a string"
          t.datetime   :updated_at, comment: "Date and Time record was last updated"
          t.bigint     :updated_by_id, comment: "user id of the user to last update the record. FK on the User table"
      end

      add_foreign_key "conference_links", "users", column: "created_by_id", validate: false
      add_foreign_key "conference_links", "users", column: "updated_by_id", validate: false
      add_foreign_key "conference_links", "hearing_days", column: "hearing_day_id", validate: false
  end
end