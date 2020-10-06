class CreateCavcRemand < Caseflow::Migration
  def change
    create_table :cavc_remands do |t|
      t.bigint "appeal_id", null: false, comment: "Appeal that CAVC has remanded"
      t.bigint "created_by_id", null: false, comment: "User that created this record"
      t.bigint "updated_by_id", null: false, comment: "User that updated this record. For MDR remands, judgement and mandate dates will be added after the record is first created."

      t.string "cavc_docket_number", null: false, comment: "Docket number of the CAVC judgement"
      t.boolean "represented_by_attorney", null: false, comment: "Whether or not the appellant was represented by an attorney"
      t.string "cavc_judge_full_name", null: false, comment: "CAVC judge that passed the judgement on the remand"
      t.string "cavc_decision_type", null: false, comment: "CAVC decision type. Expecting 'remand', 'straight_reversal', or 'death_dismissal'"
      t.string "remand_subtype", comment: "Type of remand. If the cavc_decision_type is 'remand', expecting one of 'jmp', 'jmpr', or 'mdr'. Otherwise, this can be null."
      t.date "decision_date", null: false, comment: "Date CAVC issued a decision, according to the CAVC"
      t.date "judgement_date", comment: "Date CAVC issued a judgement, according to the CAVC"
      t.date "mandate_date", comment: "Date that CAVC reported the mandate was given"
      t.bigint "decision_issue_ids", default: [], array: true, comment: "Decision issues being remanded; IDs refer to decision_issues table. For a JMR, all decision issues on the previous appeal will be remanded. For a JMPR, only some"
      t.string "instructions", null: false, comment: "Instructions and context provided upon creation of the remand record"

      t.timestamps null: false, comment: "Default timestamps"
    end
  end
end
