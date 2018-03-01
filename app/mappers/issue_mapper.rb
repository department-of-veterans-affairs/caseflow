module IssueMapper
  def self.transform_issue_hash(issue_hash)
    {
      program: issue_hash[:program].try(:[], "code"),
      issue: issue_hash[:issue].try(:[], "code"),
      level_1: issue_hash[:level_1].try(:[], "code"),
      level_2: issue_hash[:level_2].try(:[], "code"),
      level_3: issue_hash[:level_3].try(:[], "code"),
      note: issue_hash[:note],
      vacols_id: issue_hash[:vacols_id]
    }
  end
end