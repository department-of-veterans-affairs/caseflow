# frozen_string_literal: true

# UnrecognizedPartyDetail encapsulates contact information for entities that are not recognized by
# any external system of record, and therefore live in Caseflow as the source of truth.
#
# A party may be an organization or a person, as per the party_type column. The only difference is
# that person names have separate optional fields for middle, last, and suffix.

class UnrecognizedPartyDetail < CaseflowRecord
  # This polymorphism is extremely lightweight, so we opt for vanilla Ruby over STI.
  enum party_type: {
    organization: "organization",
    individual: "individual"
  }

  def first_name
    self[:name] if individual?
  end

  def name
    return self[:name] if organization?

    FullName.new(first_name, middle_name, last_name).formatted(:readable_full)
  end

  # return a hash in the same format that BgsAddressService uses
  def address
    fields = %w[address_line_1 address_line_2 address_line_3 city state zip country]
    Hash[fields.collect { |field| [field.to_sym, send(field)] }]
  end
end
