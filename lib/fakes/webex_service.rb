# frozen_string_literal: true

class Fakes::WebexService
  SAMPLE_CIPHER = "eyJwMnMiOiJvUlZHZENlck9OanYxWjhLeHRub3p4NklPUUNzTVdEdWFMakRXR09kLTh4Tk91OUVyWDQ1aUZ6TG5FY" \
                  "nlJeTZTam40Vk1kVEZHU1pyaE5pRiIsInAyYyI6MzIzMzAsImF1ZCI6ImE0ZDg4NmIwLTk3OWYtNGUyYy1hOTU4LT" \
                  "NlOGMxNDYwNWU1MSIsImlzcyI6IjU0OWRhYWNiLWJmZWUtNDkxOS1hNGU0LWMwOTQ0YTY0ZGUyNSIsImN0eSI6Ikp" \
                  "XVCIsImVuYyI6IkEyNTZHQ00iLCJhbGciOiJQQkVTMi1IUzUxMitBMjU2S1cifQ.cm6FWc6Bl4vB_utAc_bswG82m" \
                  "UXhxkITkI0tZDGzzh5TKdoWSS1Mjw.L8mGls6Kp3lsa8Wz.fLen-yV2sTpWlkLFCszQjcG5V9FhJVwoNB9Ky9BgCp" \
                  "T46cFWUe-wmyn1yIZcGxFcDcwhhKwW3PVuQQ1xjl-z63o67esrvaWAjgglSioKiOFTJF1M94d4gVj2foSQtYKzR8S" \
                  "nI6wW5X5KShcVjxjchT7xDNxnHtIZoG-Zda_aOOfz_WK18rhNcyvb-BY7cSwTMhbnuuXO0-cuJ7wNyDbvqEfWXALf" \
                  "j87a2_WopcwK-x-8TQ20bzZKUrugt0FRj6VKxOCzxDhozmWDFMRu8Dpj2UrS7Fo-JQf_I1oN0O-Dwf5r8ItcNQEu5" \
                  "X0tcRazhrHSNWfOL2DOaDyHawi4oxc7MqaNRxxyrpy2qYw06_TzBwRKlMFZ8fT7-GJbDlE3nqWlNw3mlRuvhu80CH" \
                  "SO5RK5a1obU4sfLX0Fsxl-csC-1QjcHuKOSP_ozb6l7om-WeOdbSV99Fjy68egjH1NhMQIcVwpG0fy2j8r3sN4nz0" \
                  "RSe3LXoK78JqRxk6XuaQCDkr6TmG5YjHQ2FFw1tP1ekHpNIL2oJNVAKKPgget7LRuSiM6jg.628e3hFPmZCoqXuyY" \
                  "2OriQ"

  def initialize(**args)
    @status_code = args[:status_code] || 200
    @error_message = args[:error_message] || "Error"
    @num_hosts = args[:num_hosts] || 1
    @num_guests = args[:num_guests] || 1
  end

  def create_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::CreateResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::CreateResponse.new(
      HTTPI::Response.new(
        200,
        {},
        build_meeting_response
      )
    )
  end

  def delete_conference(virtual_hearing)
    if error?
      return ExternalApi::WebexService::DeleteResponse.new(
        HTTPI::Response.new(@status_code, {}, error_response)
      )
    end

    ExternalApi::WebexService::DeleteResponse.new(
      HTTPI::Response.new(
        200,
        {},
        build_meeting_response
      )
    )
  end

  private

  def build_meeting_response
    {
      host: link_info(@num_hosts),
      guest: link_info(@num_guests),
      baseUrl: "https://instant-usgov.webex.com/visit/"
    }.to_json
  end

  def link_info(num_links = 1)
    Array.new(num_links).map do
      {
        cipher: SAMPLE_CIPHER,
        short: Faker::Alphanumeric.alphanumeric(number: 7, min_alpha: 3, min_numeric: 1)
      }
    end
  end

  def error?
    [
      400, 401, 403, 404, 405, 409, 410,
      500, 502, 503, 504
    ].include? @status_code
  end

  def error_response
    {
      message: @error_message,
      errors: [
        description: @error_message
      ],
      trackingId: "ROUTER_#{SecureRandom.uuid}"
    }.to_json
  end
end
