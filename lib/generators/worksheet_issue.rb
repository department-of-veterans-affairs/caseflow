# frozen_string_literal: true

class Generators::WorksheetIssue
  extend Generators::Base

  class << self
    def default_attrs
      {
        description: "Comp: SC\n03 - All Others; 5252 - Thigh, limitation of flexion of",
        disposition: "Remanded\n01/05/1996",
        vacols_sequence_id: 1
      }
    end

    def create(attrs = {})
      attrs[:appeal_id] ||= attrs[:appeal].try(:id) || default_appeal.id

      ::WorksheetIssue.create(default_attrs.merge(attrs))
    end

    private

    def default_appeal
      Generators::LegacyAppeal.create
    end
  end
end
