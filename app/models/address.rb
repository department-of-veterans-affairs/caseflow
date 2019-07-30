# frozen_string_literal: true

class Address
  attr_reader :country, :city, :zip_code, :address_line_1, :address_line_2, :address_line_3, :state

  def initialize(address_line_1:, address_line_2: nil, address_line_3: nil, city:, zip_code: nil, country:, state:)
    @address_line_1 = address_line_1
    @address_line_2 = address_line_2
    @address_line_3 = address_line_3
    @city = city
    @state = state
    @zip_code = zip_code
    @country = country
  end

  def zip_code_not_validatable?
    country.nil? || city.nil? || zip_code.nil?
  end

  def full_address
    "#{address_line_1}#{address_line_2}#{address_line_3}, #{city} #{state} #{zip_code}".squeeze.strip
  end
end
