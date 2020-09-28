class CreateCavcRemand < Caseflow::Migration
  def change
    create_table :cavc_remands do |t|
      t.bigint "appeal_id", null: false, comment: "Appeal the court is remanding"
      t.bigint "created_by_id", null: false, comment: "User that created this record"
      t.bigint "updated_by_id", null: false, comment: "User that updated this record. For MDR remands, judgement and mandate dates will be added after the record is first created."

      t.string "cavc_docket_number", null: false, comment: "Docket number of the CAVC judgement"
      t.boolean "attorney_represented", null: false, comment: "Whether or not the appellant was represented by an attorney"
      t.string "cavc_judge_full_name", null: false, comment: "CAVC judge that passed the judgement on the remand"
      t.string "cavc_type", null: false, comment: "CAVC Decision type. Currently one of 'Remand', 'Straight Reversal', and 'Death Dismissal'"
      t.string "remand_type", comment: "Type of remand. Can be null if the cavc decision type is not 'Remand'. One of 'JMP', 'JMPR', and 'MDR'"
      t.date "decision_date", null: false, comment: "Date CAVC issued a decision"
      t.date "judgement_date", null: false, comment: "Date CAVC issued a judgement"
      t.date "mandate_date", null: false, comment: "Date mandate was ready"
      t.bigint "decision_issue_ids", default: [], array: true, comment: "Decision issues being remanded. For a JMR, all decision issues on the previous appeal will be remanded. For a JMPR, only some"
      t.string "instructions", null: false, comment: "Intructions and context provided upon creation of the remand record"

      t.timestamps null: false, comment: "Default created_at/updated_at"
    end
  end
end
