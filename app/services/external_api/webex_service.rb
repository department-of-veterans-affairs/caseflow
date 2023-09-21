# frozen_string_literal: true

class ExternalApi::WebexService
  def create_conference(*)
    fail NotImplementedError

    body = {
      jwt: {
        sub: "A unique identifier to refer to the conference with later", # Should incorporate the docket number
        nbf: Time.zone.now.beginning_of_day.to_i, # Most likely will be the beginning scheduled hearing date
        exp: Time.zone.now.end_of_day.to_i # Most likely will be the end scheduled hearing date

      },
      aud: "a4d886b0-979f-4e2c-a958-3e8c14605e51",
      provideShortUrls: true
    }
  end

  def delete_conference(*)
    fail NotImplementedError
  end

  private

  def error?
    [].include? @status_code
  end
end
