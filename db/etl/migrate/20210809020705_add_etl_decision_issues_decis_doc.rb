# frozen_string_literal: true

class AddEtlDecisionIssuesDecisDoc < Caseflow::Migration
  def change
    add_column :decision_issues, :docket_number, :bigint,
               comment: "Docket number of associated appeal"
    add_column :decision_issues, :decision_doc_id, :bigint,
               comment: "Id of associated decision document"
    add_column :decision_issues, :doc_citation_number, :string,
               comment: "Citation number of associated decision document"
    add_column :decision_issues, :doc_decision_date, :string,
               comment: "Decision date of associated decision document"
    add_column :decision_issues, :judge_user_id, :string,
               comment: "Id of associated judge user"
    add_column :decision_issues, :judge_css_id, :string,
               comment: "CSS_ID of associated judge"
    add_column :decision_issues, :attorney_user_id, :string,
               comment: "Id of associated attorney user"
    add_column :decision_issues, :attorney_css_id, :string,
               comment: "CSS_ID of associated attorney"
  end
end
