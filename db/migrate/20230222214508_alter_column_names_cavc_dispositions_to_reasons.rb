class AlterColumnNamesCavcDispositionsToReasons < Caseflow::Migration
  def change
    safety_assured do
      change_table :cavc_dispositions_to_reasons do |t|
        # t.remove_references :cavc_dashboard_dispositions, foreign_key: true
        t.references        :cavc_dashboard_disposition, foreign_key: true, comment: "ID of the associated CAVC Dashboard Disposition", index: {:name => 'cavc_disp_to_reason_cavc_dash_disp_id'}
        # t.remove_references :cavc_selection_bases, foreign_key: true
        t.references        :cavc_selection_basis, foreign_key: true, comment: "ID of the associated CAVC Selection Bases"
        # t.remove_references :cavc_decision_reasons, foreign_key: true
        t.references        :cavc_decision_reason, foreign_key: true, comment: "ID of the associated CAVC Dashboard Issue"
      end
    end
  end
end
