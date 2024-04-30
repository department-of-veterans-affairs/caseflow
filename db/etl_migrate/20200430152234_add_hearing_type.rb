class AddHearingType < Caseflow::Migration
  def change
    add_column :hearings, :type, :string, comment: "Hearing (AMA) or LegacyHearing"
    add_column :hearings, :vacols_id, :string, comment: "When type=LegacyHearing, this column points at the VACOLS case id"
    add_column :hearings, :judge_css_id, :string, comment: "users.css_id"
    add_column :hearings, :judge_full_name, :string, comment: "users.full_name"
    add_column :hearings, :judge_sattyid, :string, comment: "users.sattyid"

    change_column_null :hearings, :uuid, true

    add_safe_index :hearings, :type
    add_safe_index :hearings, :vacols_id
    add_safe_index :hearings, :judge_id
  end
end
