class Generators::Issue
  extend Generators::Base

  class << self
    def default_attrs
      {
        disposition: "Allowed",
        description: [
          "15 - Service connection",
          "03 - All Others",
          "5252 - Thigh, limitation of flexion of"
        ],
        levels: [
          "All Others",
          "Thigh, limitation of flexion of"
        ],
        program_description: "02 - Compensation",
        program: :compensation,
        type: {name: :service_connection, label: "Service Connection"},
        category: :knee
      }
    end

    def build(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || Generators::Appeal.create.id

      issue = ::Issue.new(default_attrs.merge(attrs))

      if issue.appeal.vacols_id
        Fakes::AppealRepository.issue_records ||= {}
        Fakes::AppealRepository.issue_records[issue.appeal.vacols_id] ||= []
        Fakes::AppealRepository.issue_records[issue.appeal.vacols_id].push(issue)
      end

      issue
    end
  end
end
