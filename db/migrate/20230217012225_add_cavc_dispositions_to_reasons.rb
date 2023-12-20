class AddCavcDispositionsToReasons < Caseflow::Migration
  def change
    create_table :cavc_dispositions_to_reasons do |t|
      t.references :cavc_dashboard_disposition, foreign_key: true, comment: "ID of the associated CAVC Dashboard Disposition", index: {:name => 'cavc_disp_to_reason_cavc_dash_disp_id'}
      t.references :cavc_decision_reason, foreign_key: true, comment: "ID of the associated CAVC Decision Reason"
      t.references :cavc_selection_basis, foreign_key: true, comment: "ID of the associated CAVC Basis for Selection"
      t.bigint     :created_by_id, comment: "The ID for the user that created the record"
      t.bigint     :updated_by_id, comment: "The ID for the user that most recently changed the record"
      t.timestamps
    end
  end
end
