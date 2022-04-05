class CreateConferenceLink < ActiveRecord::Migration[5.2]
    def change
        create_table :conference_link, id: false do |t|
            t.belongs_to :hearing_day
            t.bigint     :id, null: false
            t.string     :alias
            t.string     :alias_with_host
            t.boolean    :conference_deleted, default: false, null: false
            t.integer    :conference_id
            t.datetime   :created_at, null: false 
            t.bigint     :created_by_id, null: false
            t.bigint     :hearing_day_id, null: false
            t.string     :host_hearing_link, null: false 
            t.integer    :host_pin, null: false
            t.string     :host_pin_long, limit: 8, null: false  
            t.datetime   :updated_at
            t.bigint     :update_by_id, null: false
        end
    end
end
