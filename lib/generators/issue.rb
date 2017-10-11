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
        levels: ["All Others", "Thigh, limitation of flexion of"],
        program_description: "02 - Compensation",
        program: :compensation,
        type: { name: :service_connection, label: "Service Connection" },
        category: :knee,
        note: "low back condition",
        vacols_sequence_id: 1,
        id: SecureRandom.random_number(1_000_000)
      }
    end

    def build(attrs = {})
      vacols_id ||= attrs.delete(:vacols_id)
      issue = ::Issue.new(default_attrs.merge(attrs))

      if vacols_id
        Fakes::AppealRepository.issue_records ||= {}
        Fakes::AppealRepository.issue_records[vacols_id] ||= []
        Fakes::AppealRepository.issue_records[vacols_id].push(issue)        
      end
    end
  end
end
