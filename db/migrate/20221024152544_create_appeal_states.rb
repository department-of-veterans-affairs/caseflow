class CreateAppealStates < Caseflow::Migration
  def change
    create_table :appeal_states do |t|
      t.bigint :appeal_id, null: false, comment: "AMA or Legacy Appeal ID"
      t.string :appeal_type, null: false, comment: "Appeal Type (Appeal or LegacyAppeal)"
      t.bigint :updated_by_id, null: true, references: [:users, :id], comment: "User id of the last user that updated the record"
      t.bigint :created_by_id, null: false, references: [:users, :id], comment: "User id of the user that inserted the record"
      t.boolean :appeal_docketed, null: false, default: false, comment: "When true, appeal has been docketed"
      t.boolean :privacy_act_pending, null: false, default: false, comment: "When true, appeal has a privacy act request still open"
      t.boolean :privacy_act_complete, null: false, default: false, comment: "When true, appeal has a privacy act request completed"
      t.boolean :vso_ihp_pending, null: false, default: false, comment: "When true, appeal has a VSO IHP request pending"
      t.boolean :vso_ihp_complete, null: false, default: false, comment: "When true, appeal has a VSO IHP request completed"
      t.boolean :hearing_scheduled, null: false, default: false, comment: "When true, appeal has at least one hearing scheduled"
      t.boolean :hearing_postponed, null: false, default: false, comment: "When true, appeal has hearing postponed and no hearings scheduled"
      t.boolean :hearing_withdrawn, null: false, default: false, comment: "When true, appeal has hearing withdrawn and no hearings scheduled"
      t.boolean :decision_mailed, null: false, default: false, comment: "When true, appeal has decision mail request complete"
      t.boolean :appeal_cancelled, null: false, default: false, comment: "When true, appeal's root task is cancelled"
      t.boolean :scheduled_in_error, null: false, default: false, comment: "When true, hearing was scheduled in error and none scheduled"
      t.timestamps
    end
  end
end
