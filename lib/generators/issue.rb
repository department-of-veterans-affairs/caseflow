class Generators::Issue
  extend Generators::Base

  class << self
    def default_attrs
      {
        disposition: "Allowed",
        description_label: "Service connection",
        description: [
          "15 - Service connection",
          "03 - All Others",
          "5252 - Thigh, limitation of flexion of"
        ],
        levels: ["All Others", "Thigh, limitation of flexion of"],
        program_description: "02 - Compensation",
        program: :compensation,
        type: :service_connection,
        category: :knee
      }
    end

    def build(attrs = {})
      attrs[:appeal_id] = attrs[:appeal].try(:id)

      vacols_id ||= attrs.delete(:vacols_id) || attrs[:appeal].try(:vacols_id)
      issue = ::Issue.new(default_attrs.merge(attrs))

      if vacols_id
        Fakes::AppealRepository.issue_records ||= {}
        Fakes::AppealRepository.issue_records[vacols_id] ||= []
        Fakes::AppealRepository.issue_records[vacols_id].push(issue)
        issue.vacols_sequence_id = Fakes::AppealRepository.issue_records[vacols_id].length
      end

      issue
    end
  end
end
