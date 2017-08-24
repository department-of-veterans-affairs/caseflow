class IssueRepository
  class << self
    def load_vacols_data(issue)
      binding.pry
      issue_hash = issue.appeal.issues.select{ |i| i[:vacols_sequence_id] == issue.vacols_sequence_id }
      issue.assign_from_vacols(issue_hash)
      true
    rescue ActiveRecord::RecordNotFound
      false
    end
  end
end
