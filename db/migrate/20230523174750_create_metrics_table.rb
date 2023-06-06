class CreateMetricsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :metrics do |t|
      t.uuid       :uuid, default: -> { "uuid_generate_v4()" }, null: false, comment: "Unique ID for the metric, can be used to search within various systems for the logging"
      t.references :user, null: false, foreign_key: true, comment: "The ID of the user who generated metric."
      t.string     :metric_name, null: false, comment: "Name of metric"
      t.string     :metric_class, null: false, comment: "Class of metric, use reflection to find value to populate this"
      t.string     :metric_group, null: false, default: "service", comment: "Metric group: service, etc"
      t.string     :metric_message, null: false, comment: "Message or log for metric"
      t.string     :metric_type, null: false, comment: "Type of metric: ERROR, LOG, PERFORMANCE, etc"
      t.string     :metric_product, null: false, comment: "Where in application: Queue, Hearings, Intake, VHA, Case Distribution, etc"
      t.string     :app_name, null: false, comment: "Application name: caseflow or efolder"
      t.json       :metric_attributes, comment: "Store attributes relevant to the metric: OS, browser, etc"
      t.json       :additional_info, comment: "additional data to store for the metric"
      t.string     :sent_to, array: true, comment: "Which system metric was sent to: Datadog, Rails Console, Javascript Console, etc "
      t.json       :sent_to_info, comment: "Additional information for which system metric was sent to"
      t.json       :relevant_tables_info, comment: "Store information to tie metric to database table(s)"
      t.timestamp  :start, comment: "When metric recording started"
      t.timestamp  :end, comment: "When metric recording stopped"
      t.bigint     :duration, comment: "Time in milliseconds from start to end"
      t.timestamps
    end
  end
end
