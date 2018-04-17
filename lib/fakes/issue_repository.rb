class Fakes::IssueRepository
  CODE_KEYS = [:program, :issue, :level_1, :level_2, :level_3].freeze

  class << self
    def create_vacols_issue!(args)
      issue_attrs = args[:issue_attrs]

      init_issue_records(issue_attrs[:vacols_id])
      repo_issue = Fakes::AppealRepository.issue_records[issue_attrs[:vacols_id]]

      issue = Generators::Issue.build(
        disposition: nil,
        close_date: nil,
        codes: CODE_KEYS.collect { |k| issue_attrs[k] }.compact,
        labels: repo_issue.present? ? repo_issue.first.labels : :not_loaded,
        note: issue_attrs[:note],
        vacols_sequence_id: Fakes::AppealRepository.issue_records[issue_attrs[:vacols_id]].size + 1,
        id: issue_attrs[:vacols_id]
      )

      Fakes::AppealRepository.issue_records[issue_attrs[:vacols_id]] << issue
    end

    def update_vacols_issue!(args)
      issue_attrs = args[:issue_attrs]
      record = find_issue(args[:vacols_id], args[:vacols_sequence_id])
      record.codes = CODE_KEYS.collect { |k| issue_attrs[k] }.compact
      record.note = issue_attrs[:note]
    end

    def delete_vacols_issue!(args)
      record = find_issue(args[:vacols_id], args[:vacols_sequence_id])
      Fakes::AppealRepository.issue_records[args[:vacols_id]].delete(record)
    end

    def find_issue(vacols_id, vacols_sequence_id)
      init_issue_records(vacols_id)

      record = Fakes::AppealRepository.issue_records[vacols_id]
        .find { |i| i.vacols_sequence_id == vacols_sequence_id.to_i }

      unless record
        msg = "Cannot find issue with vacols ID: #{vacols_id} and sequence ID: #{vacols_sequence_id} in VACOLS"
        fail IssueRepository::IssueError, msg
      end
      record
    end

    def init_issue_records(vacols_id)
      Fakes::AppealRepository.issue_records ||= {}
      Fakes::AppealRepository.issue_records[vacols_id] ||= []
    end
  end
end
