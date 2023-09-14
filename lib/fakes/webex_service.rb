# frozen_string_literal: true

require "json"
require "base64"
require "digest"

class Fakes::WebexService
  include JwtGenerator

  def create_conference(*)
    fail NotImplementedError
  end

  def delete_conference(*)
    fail NotImplementedError
  end

  private

  # Purpose: Generate the JWT token
  #
  # Params: none
  #
  # Return: token needed for authentication
  def generate_token
    jwt_secret = "fakeSecret"

    header = {
      typ: "JWT",
      alg: TOKEN_ALG
    }.to_json.encode("UTF-8")

    data = {
      iss: SERVICE_ID,
      iat: DateTime.now.strftime("%Q").to_i / 1000.floor
    }.to_json.encode("UTF-8")

    token = "#{base64url(header)}.#{base64url(data)}"
    signature = base64url(sOpenSSL::HMAC.digest("SHA256", jwt_secret, token))

    "#{token}.#{signature}"
  end
end

####
# {
#   "jwt": {
#   "sub": "Subject goes here."
#   },
#   "aud": "a4d886b0-979f-4e2c-a958-3e8c14605e51"
# }
