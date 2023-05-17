# frozen_string_literal: true

class VbmsDistributionDestination < CaseflowRecord
  belongs_to :vbms_distribution, optional: false

  with_options presence: true do
    # Question of whether "derived" is necessary destination_type to check for, or if only relevant to VBMS
    validates :destination_type, inclusion: { in: %w[domesticAddress internationalAddress militaryAddress derived] }
    validates :address_line_1, :city, :country_code, if: :physical_mail?
    validates :address_line_2, if: :treat_line_2_as_addressee
    validates :address_line_3, if: :treat_line_3_as_addressee
    validates :state, :postal_code, if: :us_address?
    validates :country_name, if: -> { destination_type == "internationalAddress" }
  end

  validate :valid_country_code?, if: :physical_mail?
  validate :valid_us_state_code?, if: :us_address?

  def physical_mail?
    %w[domesticAddress internationalAddress militaryAddress].include?(destination_type)
  end

  def us_address?
    %w[domesticAddress militaryAddress].include?(destination_type)
  end

  def valid_country_code?
    unless iso_country_codes.include?(country_code)
      errors.add(:country_code, "is not a valid ISO 3166-2 code")
    end
  end

  def valid_us_state_code?
    unless iso_us_state_codes.include?(state)
      errors.add(:state, "is not a valid ISO 3166-2 code")
    end
  end

  # Are these country and state codes available in a hard coded constant – or can I create?

  def iso_country_codes
    @iso_country_codes ||= ISO3166::Country.codes
  end

  def iso_us_state_codes
    @iso_us_state_codes ||= ISO3166::Country.find_country_by_alpha2("US").subdivisions.keys
  end
end
