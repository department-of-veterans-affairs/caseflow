# frozen_string_literal: true

class TimezoneService
  # Could not find the country by name.
  class InvalidCountryNameError < StandardError; end

  # Could not find country by code.
  class InvalidCountryCodeError < StandardError; end

  # Could not find a timezone by zip code.
  class InvalidZip5Error < StandardError; end

  # There were multiple timezones for an address.
  class AmbiguousTimezoneError < StandardError; end

  class << self
    # Attempts to find a timezone based on an address. For addresses within the United States,
    # this does a lookup of timezone based on zip code. For addresses outisde of the US,
    # this does a lookup based on country code.
    #
    # Fails if there are multiple timezones for a country outside of the US.
    # Fails if country name or zip code are formatted incorrectly.
    def address_to_timezone(address)
      # Return addresses for addresses in US using zip code before calling
      # iso3166_alpha2_code_from_name() because that method will raise an error given country "US".
      if address.country == "US"
        return TimezoneService.zip5_to_timezone(address.zip)
      end

      iso3166_code = TimezoneService.iso3166_alpha2_code_from_name(address.country)

      if iso3166_code == "US"
        TimezoneService.zip5_to_timezone(address.zip)
      else
        TimezoneService.iso3166_alpha2_code_to_timezone(iso3166_code)
      end
    end

    # Maps a US 5-digit zip code to a timezone.
    def zip5_to_timezone(zip)
      Address.validate_zip5_code(zip)

      timezone_name = Ziptz.new.time_zone_name(zip)

      fail InvalidZip5Error, "could not find timezone for zip code \"#{zip}\"" if timezone_name.blank?

      TZInfo::Timezone.get(timezone_name)
    rescue ArgumentError
      # Zip code is in an invalid format
      raise InvalidZip5Error, "invalid zip code \"#{zip}\""
    rescue TZInfo::InvalidTimezoneIdentifier
      # For military zip codes, `ziptz` returns "APO/FPO", which causes an invalid timezone error.
      raise InvalidZip5Error, "could not find timezone for zip code \"#{zip}\""
    end

    # Maps an ISO 3166 country code to a timezone.
    #
    # Note: A country may span across multiple different timezones. If this is the case,
    # this function will fail with an error, unless every timezone the country spans has
    # the same offset from UTC.
    def iso3166_alpha2_code_to_timezone(iso3166_code)
      country = TZInfo::Country.get(iso3166_code)

      unambiguous_timezone = (
        country.zones.size == 1 ||
        country.zones.map(&:current_period).map(&:utc_offset).uniq.size == 1
      )

      return country.zones.first.canonical_zone if unambiguous_timezone

      fail AmbiguousTimezoneError, "ambiguous timezone for #{iso3166_code}"
    rescue TZInfo::InvalidCountryCode
      # Re-raise custom error for more info.
      raise InvalidCountryCodeError, "invalid country code \"#{iso3166_code}\""
    end

    # Finds the ISO 3166 country code corresponding to the given country name, or fails
    # with an error if not found.
    def iso3166_alpha2_code_from_name(country_name)
      iso3166_code = ISO3166::Country.find_country_by_name(country_name)
      iso3166_code = ISO3166::Country.find_country_by_alpha3(country_name) if iso3166_code.blank?

      if iso3166_code.blank?
        fail InvalidCountryNameError, "no ISO 3166 country code found for \"#{country_name}\""
      end

      iso3166_code.alpha2
    end
  end
end
