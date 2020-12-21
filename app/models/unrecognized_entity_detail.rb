# frozen_string_literal: true

# UnrecognizedEntityDetail encapsulates contact information for entities that are not recognized by
# any external system of record, and therefore live in Caseflow as the source of truth.
#
# An entity may be an organization or a person, as per the entity_type column. The only difference is
# that person names have separate optional fields for middle, last, and suffix.

class UnrecognizedEntityDetail < CaseflowRecord
  enum entity_type: {
    organization: "organization",
    person: "person"
  }

  def first_name
    self[:name] if person?
  end

  def name
    return self[:name] if organization?

    %w[name middle_name last_name suffix].map { |key| self[key].presence }.compact.join(" ")
  end
end
