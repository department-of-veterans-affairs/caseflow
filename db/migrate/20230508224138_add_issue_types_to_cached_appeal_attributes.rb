class AddIssueTypesToCachedAppealAttributes < Caseflow::Migration
  def change
    add_column :cached_appeal_attributes, :issue_types, :string, comment: "A string delimited list of nonrating issue categories on the appeal."
  end
end
