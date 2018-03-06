class Fakes::IssueRepository
  class << self
    def create_vacols_issue(*)
      Fakes::AppealRepository.issue_records ||= {}
      Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]] ||= []

      keys = [:program, :issue, :level_1, :level_2, :level_3]
      issue = Generators::Issue.build(
        disposition: nil,
        close_date: nil,
        codes: keys.collect { |k| issue_hash[k]["code"] if issue_hash[k] }.compact,
        labels: keys.collect { |k| issue_hash[k]["description"] if issue_hash[k] }.compact,
        note: issue_hash[:note],
        vacols_sequence_id: Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]].size + 1,
        id: issue_hash[:vacols_id]
      )

      Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]] << issue

      issue
    end

    def update_vacols_issue(*)
      true
    end
  end
end
