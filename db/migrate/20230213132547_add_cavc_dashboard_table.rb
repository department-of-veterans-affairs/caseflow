class AddCavcDashboardTable < Caseflow::Migration
  def change
    create_table :cavc_dashboards do |t|
      t.references :cavc_remand, foreign_key: true, comment: "ID of the associated CAVC Remand"
      t.date       :board_decision_date, comment: "The decision date of the source appeal"
      t.string     :board_docket_number, comment: "The docket number of the source appeal"
      t.date       :cavc_decision_date, comment: "The decision date from the CAVC board"
      t.string     :cavc_docket_number, comment: "The docket number assigned by the CAVC board"
      t.boolean    :joint_motion_for_remand, comment: "Whether the CAVC appeal is JMR/JMPR or not"
      t.bigint     :created_by_id, comment: "The ID for the user that created the record"
      t.bigint     :updated_by_id, comment: "The ID for the user that most recently changed the record"
      t.timestamps
    end

    safety_assured do
      change_table :cavc_dashboard_dispositions do |t|
        t.remove_references :cavc_remand, foreign_key: true
        t.references        :cavc_dashboard, foreign_key: true, comment: "ID of the associated CAVC Dashboard"
      end

      change_table :cavc_dashboard_issues do |t|
        t.remove_references :cavc_remand, foreign_key: true
        t.references        :cavc_dashboard, foreign_key: true, comment: "ID of the associated CAVC Dashboard"
      end
    end
  end
end
