# frozen_string_literal: true

module MailRequestValidator
  module Distribution
    extend ActiveSupport::Concern

    included do
      with_options presence: true do
        validates :recipient_type, inclusion: { in: %w[organization person system ro-colocated] }
        validates :first_name, :last_name, if: -> { recipient_type == "person" }
        validates :name, if: :not_a_person?
        validates :poa_code, :claimant_station_of_jurisdiction, if: -> { recipient_type == "ro-colocated" }
      end
    end

    private

    def not_a_person?
      %w[organization system ro-colocated].include?(recipient_type)
    end
  end

  module DistributionDestination
    extend ActiveSupport::Concern

    included do
      with_options presence: true do
        validates :destination_type, inclusion: { in: %w[domesticAddress internationalAddress militaryAddress derived] }
        validates :address_line_1, :city, :country_code, if: :physical_mail?
        validates :address_line_2, if: :treat_line_2_as_addressee
        validates :address_line_3, if: :treat_line_3_as_addressee
        validates :state, :postal_code, if: :us_address?
        validates :country_name, if: -> { destination_type == "internationalAddress" }
      end

      validates :treat_line_2_as_addressee,
                inclusion: { in: [true], message: "cannot be false if line 3 is treated as addressee" },
                if: -> { treat_line_3_as_addressee == true }

      validate :valid_country_code?, if: :physical_mail?
      validate :valid_us_state_code?, if: :us_address?
    end

    private

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

    def iso_country_codes
      @iso_country_codes ||= ISO3166::Country.codes
    end

    def iso_us_state_codes
      @iso_us_state_codes ||= ISO3166::Country.find_country_by_alpha2("US").subdivisions.keys
    end
  end
end
