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

    FullName.new(first_name, middle_name, last_name).formatted(:readable_full_nonformatted)
  end

  # return a hash in the same format that BgsAddressService uses
  def address
    fields = %w[address_line_1 address_line_2 address_line_3 city state zip country]
    Hash[fields.collect { |field| [field.to_sym, send(field)] }]
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: unrecognized_party_details
#
#  id             :bigint           not null, primary key
#  address_line_1 :string           not null
#  address_line_2 :string
#  address_line_3 :string
#  city           :string           not null
#  country        :string           not null
#  date_of_birth  :date
#  email_address  :string
#  last_name      :string
#  middle_name    :string
#  name           :string           not null
#  party_type     :string           not null
#  phone_number   :string
#  state          :string           not null
#  suffix         :string
#  zip            :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
