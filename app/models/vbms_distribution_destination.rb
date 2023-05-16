# frozen_string_literal: true

class VbmsDistributionDestination < CaseflowRecord
  belongs_to :vbms_distribution, optional: false

  with_options presence: true do
    validates :destination_type, inclusion: { in: %w(domesticAddress internationalAddress militaryAddress derived email sms) }
    validates :address_line_1, :city, :country_code, if: :is_physical_mail?
    validates :address_line_2, if: :treat_line_2_as_addressee
    validates :address_line_3, if: :treat_line_3_as_addressee
    validates :state, :postal_code, if: :is_us_address?
    validates :country_name, if: -> { destination_type == "internationalAddress" }
    validates :email_address, if: -> { destination_type == "email" }
    validates :phone_number, if: -> { destination_type == "sms" }
  end

  validate :is_valid_country_code?, if: :is_physical_mail?
  validate :is_valid_us_state_code?, if: :is_us_address?

  def is_physical_mail?
    %w(domesticAddress internationalAddress militaryAddress).include?(destination_type)
  end

  def is_us_address?
    %w(domesticAddress militaryAddress).include?(destination_type)
  end

  def is_valid_country_code?
    unless iso_country_codes.include?(country_code)
      errors.add(:country_code, "is not a valid ISO 3166-2 code")
    end
  end

  def is_valid_us_state_code?
    unless iso_us_state_codes.include?(state)
      errors.add(:state, "is not a valid ISO 3166-2 code")
    end
  end

  # Are these country and state codes available in a hard coded constant – or should I create?

  def iso_country_codes
    @iso_country_codes ||= ISO3166::Country.codes
  end

  def iso_us_state_codes
    @iso_us_state_codes ||= ISO3166::Country.find_country_by_alpha2("US").subdivisions.keys
  end
end
