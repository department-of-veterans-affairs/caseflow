class CreateMetricsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :metrics do |t|
      t.uuid       :uuid, default: -> { "uuid_generate_v4()" }, null: false, comment: "Unique ID for the metric, can be used to search within various systems for the logging"
      t.references :user, null: false, foreign_key: true, comment: "The ID of the user who generated metric."
      t.string     :type, null: false, comment: "Type of metric: ERROR, LOG, PERFORMANCE, etc"
      t.string     :message, comment: "Message to accompany metric"
      t.string     :sent_to, array: true, comment: "Which system metric was sent to: Datadog, Rails Console, Javascript Console, etc "
      t.json       :sent_to_info, comment: "Which system metric was sent to: Datadog, Rails Console, Javascript Console, etc "
      t.string     :relevant_table, comment: "Indicates which table relevant_table_id applies to"
      t.bigint     :relevant_table_id, comment: "Allows for psuedo foreign keys to be used in queries"
      t.json       :relevant_tables_info, comment: "Store additional information to tie metric to database tables"
      t.json       :info, comment: "Store extra information relevant to the metric: OS, browser, etc"
      t.timestamp  :start, comment: "When metric recording started"
      t.timestamp  :end, comment: "When metric recording stopped"
      t.bigint     :duration, comment: "Time in milliseconds from start to end"
      t.json       :stats, comment: "Store stats for the metric"
      t.timestamps
    end
  end
end
