class Generators::WorksheetIssue
  extend Generators::Base

  class << self
    def default_attrs
      {
        description: [
          "15 - Service connection",
          "03 - All Others",
          "5252 - Thigh, limitation of flexion of"
        ],
        levels: ["All Others", "Thigh, limitation of flexion of"],
        program: :compensation,
        name: :service_connection,
        vacols_sequence_id: 1
      }
    end

    def create(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal.id

      ::WorksheetIssue.create(default_attrs.merge(attrs))
    end

    private

    def default_appeal
      Generators::Appeal.create
    end
  end
end
