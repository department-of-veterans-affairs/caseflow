class Fakes::IssueRepository
  class << self
    def create_vacols_issue(css_id:, issue_hash:)
      Fakes::AppealRepository.issue_records ||= {}
      Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]] ||= []

      keys = [:program, :issue, :level_1, :level_2, :level_3]
      issue = Generators::Issue.build(
        disposition: nil,
        close_date: nil,
        codes: keys.collect { |k| issue_hash[k][:code] if issue_hash[k] }.compact,
        labels: keys.collect { |k| issue_hash[k][:description] if issue_hash[k] }.compact,
        note: issue_hash[:note],
        vacols_sequence_id: Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]].size + 1,
        id: issue_hash[:vacols_id]
      )

      Fakes::AppealRepository.issue_records[issue_hash[:vacols_id]] << issue

      issue
    end

    def update_vacols_issue(css_id:, vacols_id:, vacols_sequence_id:, issue_hash:)
      record = find_issue(vacols_id, vacols_sequence_id)
      keys = [:program, :issue, :level_1, :level_2, :level_3]
      record.codes = keys.collect { |k| issue_hash[k][:code] if issue_hash[k] }.compact
      record.labels = keys.collect { |k| issue_hash[k][:description] if issue_hash[k] }.compact
      record.note = issue_hash[:note]
      record
    end

    def find_issue(vacols_id, vacols_sequence_id)
      Fakes::AppealRepository.issue_records ||= {}
      Fakes::AppealRepository.issue_records[vacols_id] ||= []

      record = Fakes::AppealRepository.issue_records[vacols_id].find { |i| i.vacols_sequence_id == vacols_sequence_id.to_i }
      unless record
        msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
        fail IssueRepository::IssueError, msg
      end
      record
    end
  end
end
