# frozen_string_literal: true

class Address
  ZIP_CODE_REGEX = /(?i)^[a-z0-9][a-z0-9\- ]{0,10}[a-z0-9]$/.freeze

  attr_reader :country, :city, :zip, :address_line_1, :address_line_2, :address_line_3, :state

  # rubocop:disable Metrics/ParameterLists
  def initialize(
    address_line_1: nil, address_line_2: nil, address_line_3: nil,
    city:, zip: nil, country: nil, state: nil
  )
    # rubocop:enable Metrics/ParameterLists
    @address_line_1 = address_line_1
    @address_line_2 = address_line_2
    @address_line_3 = address_line_3
    @city = city
    @state = state
    @zip = zip
    @country = country
  end

  def zip_code_not_validatable?
    country.nil? || city.nil? || zip.nil?
  end

  def full_address
    addr = address_line_1.to_s
    addr += " #{address_line_2}" unless address_line_2.blank?
    addr += " #{address_line_3}" unless address_line_3.blank?
    addr += ", #{city} #{state} #{zip}"

    addr.strip
  end
end
