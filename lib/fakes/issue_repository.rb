class Fakes::IssueRepository
  class << self
    def load_vacols_data(issue)
      return false if Fakes::AppealRepository.issue_records.blank? || !issue.appeal
      issues_for_appeal = Fakes::AppealRepository.issue_records[issue.appeal.vacols_id]
      record = issues_for_appeal.find { |i| i.vacols_sequence_id == issue.vacols_sequence_id }
      return false unless record
      issue.assign_from_vacols(record.vacols_attributes)
      true
    end
  end
end
