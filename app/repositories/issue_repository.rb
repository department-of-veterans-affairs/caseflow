class IssueRepository
  class << self
    def load_vacols_data(issue)
      return if !issue || !issue.appeal || !issue.vacols_sequence_id
      result = issue.appeal.issue_by_sequence_id(issue.vacols_sequence_id)
      issue.assign_from_vacols(result.vacols_attributes)
      true
    rescue ActiveRecord::RecordNotFound
      false
    end
  end
end
