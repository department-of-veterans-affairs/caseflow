class AddCavcReasonsToBases < ActiveRecord::Migration[5.2]
  def change
    create_table :cavc_reasons_to_bases do |t|
      t.references :cavc_dispositions_to_reason, foreign_key: true, comment: "ID of the associated CAVC Decision Reason"
      t.references :cavc_selection_basis, foreign_key: true, comment: "ID of the associated CAVC Basis for Selection"
      t.bigint     :created_by_id, comment: "The ID for the user that created the record"
      t.bigint     :updated_by_id, comment: "The ID for the user that most recently changed the record"
      t.timestamps
    end

    safety_assured do
      reversible do |dir|
        dir.up do
          remove_columns :cavc_dispositions_to_reasons, :cavc_selection_basis_id
        end

        dir.down do
          change_table :cavc_dispositions_to_reasons do |t|
            t.references :cavc_selection_basis, foreign_key: true, comment: "ID of the associated CAVC Basis for Selection"
          end
        end
      end
    end
  end
end
