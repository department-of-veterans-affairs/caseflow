# frozen_string_literal: true

class UnrecognizedEntityDetail < CaseflowRecord
  enum entity_type: {
    organization: "organization",
    person: "person"
  }

  def first_name
    name if person?
  end
end
