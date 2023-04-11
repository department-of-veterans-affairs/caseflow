class ExternalApi::JwtToken

    # Purpose: Generate the JWT token
    #
    # Params: none
    #
    # Return: token needed for authentication
    def self.generate_token(client_secret, token_alg, service_id)
      jwt_secret = client_secret
      header = {
        typ: "JWT",
        alg: token_alg
      }
      current_timestamp = DateTime.now.strftime("%Q").to_i / 1000.floor
      data = {
        iss: service_id,
        iat: current_timestamp
      }
      stringified_header = header.to_json.encode("UTF-8")
      encoded_header = base64url(stringified_header)
      stringified_data = data.to_json.encode("UTF-8")
      encoded_data = base64url(stringified_data)
      token = "#{encoded_header}.#{encoded_data}"
      signature = OpenSSL::HMAC.digest("SHA256", jwt_secret, token)
      signature = base64url(signature)
      signed_token = "#{token}.#{signature}"
      signed_token
    end
end
