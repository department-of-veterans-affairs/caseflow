class VaDotGovAddressValidator
  attr_accessor :appeal

  def initialize(appeal:)
    @appeal = appeal
  end

  def validate
    begin
      valid_address = validate_appellant_address
    rescue Caseflow::Error::VaDotGovLimitError => error
      raise error
    rescue Caseflow::Error::VaDotGovAPIError => error
      valid_address = validate_zip_code
      raise error if valid_address.nil?
    end

    valid_address
  end

  private

  def address
    @address ||= appeal.is_a?(LegacyAppeal) ? appeal.appellant[:address] : appeal.appellant.address
  end

  def validate_appellant_address
    VADotGovService.validate_address(
      address_line1: address[:address_line1],
      address_line2: address[:address_line2],
      address_line3: address[:address_line3],
      city: address[:city],
      state: address[:state],
      country: address[:country],
      zip_code: address[:zip_code]
    )
  end

  def validate_zip_code
    if address[:zip].nil? || address[:state].nil? || address[:country].nil?
      nil
    else
      lat_lng = ZipCodeToLatLngMapper::MAPPING[address[:zip][0..4]]

      return nil if lat_lng.nil?

      { lat: lat_lng[0], long: lat_lng[1], country_code: address[:country], state_code: address[:state] }
    end
  end
end
