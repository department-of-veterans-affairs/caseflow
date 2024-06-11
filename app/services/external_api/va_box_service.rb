require 'net/http'
require 'json'
require 'jwt'
require 'openssl'
require 'securerandom'

class ExternalApi::VaBoxService
  BASE_URL = "https://api.box.com"

  def initialize(config:)
    @config = config
  end

  def initialized?
    @initialized
  end

  def fetch_access_token
    begin
      # Try to use the access token
      response = fetch_jwt_access_token
      @access_token = response['access_token']
    rescue AccessTokenExpiredError
      # Fetch a new JWT access token
      response = fetch_jwt_access_token
      @access_token = response['access_token']
    end
  end

  private

  def fetch_jwt_access_token
    url = "#{BASE_URL}/oauth2/token"
    payload = {
      iss: @config[:client_id],
      sub: @config[:enterprise_id],
      box_sub_type: 'enterprise',
      aud: url,
      jti: SecureRandom.uuid,
      exp: (Time.now.utc + 60).to_i
    }

    key_content = "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n"
    # passphrase = "b2da98d5df06a6bfc3b9824209d6eb17"
    rsa_private = OpenSSL::PKey::RSA.new(key_content)
    token = JWT.encode(payload, rsa_private, 'RS256')

    body = {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: token,
      client_id: @config[:client_id],
      client_secret: @config[:client_secret]
    }

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = body.to_json

    response = http.request(request)

    if response.code == "200"
      body = JSON.parse(response.body)
      if body['expires_in'] <= Time.now.to_i
        raise AccessTokenExpiredError, 'Access token is expired'
      end
      body
    else
      raise "Error: #{response.body}"
    end
  end
end


# {
#   "boxAppSettings": {
#     "clientID": "em2hg82aw4cgee9bwjii96humn99n813",
#     "clientSecret": "sCHkWIqw2H6ewrYjzObSXTtxMDPZpH2o",
#     "appAuth": {
#       "publicKeyID": "3awcj163",
#       "privateKey": "-----BEGIN ENCRYPTED PRIVATE KEY-----\nMIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAQIoz61tzppMpUCAggA\nMAwGCCqGSIb3DQIJBQAwFAYIKoZIhvcNAwcECMJdArOHrtfGBIIEyMAUJ5NTd6ZS\nvt+hiiQ9FzSCsBsBgBcKaxJvJI+2LYYqiJuZy06NgrSadPTEXruOfAXUfMmIY4vL\nd9RqrizzsOgUPRbG6oAiwuHlCPSeK84mX3PfR4Xglh033HO1yVclcyR/2O6rMS6I\ntkDivRzPIdN/SMKPTP91ZV1k1jQFNkmneW2MyNuBESFSg6aG3Z1fQmJFk7/ACR6n\nzFe8gYjcohK7T/RQhkNDelQir0xHmWIBA55N1+cOWasNUZClrbbj7gobPakTXXin\n3qo/YvE1GYo1sgiucyBx9S4lhsFRmsGeygi5vuukDreOmzCZ5M306oXzKuD7Gj+8\nAGbFs5n+8fRSdb3ZN9EaQF1bDwaZbkMViC+I8c5Ce+7+Q0vB55w47880JZCPTQke\nXOAwGSE6y2ylGl1a26lkNt/4W4dJk6JKF3Mp0MvzTwbAOMEUP5i0UBDWxGEVHf7L\nn6wKpkLLZQnRhSYO24MWuK6n17FLX0eobT7Ih6X1gAgg5BEtsdpMGatrS9uNUb5K\n+GDjGuf134J7wa4tKb+1pE+NTx5C0fRYu6zveEhMCgBOnUUrYVKfnEy/sgcjrOJN\nA8cS34w5ZJ/MqKz0CH8Yd5VnDSHKGxRnumxWwY/eSIvs5yaL0z3aO5qebImzDsOI\niKT6TK+1KXuq5lZyVqATOsMJ6+eLaAHlbhHEGeoRalJXIs2c/7AEoa3EY3nQawsP\nJIvZImffjZM1ESirrnECfq+/QW3fIr3WKXS+yV4xV4/1AVhi4WPvd/xd6KOL/jn3\nuPh4rciaGc0tMODUa36LTKOCUGMVBfVVhtAY/Z2fgwNmXPJXS+Po5W11W1obBu5f\nuOJf2qQ5wOZVK3XFyrXWobmTud7aQDIcMlebfSLyj+BaFsacEWke/nj1BpOygYB7\nY3g827qp0S+4bcDwrwPBQswBBG0bqaUbxXgJc7bfqh9sTAFK7TBOkCgxic17I2d4\ncUMj8C3J4t/IjLgfLRUW7IhddqcctPDEIcpxyqH1L1ZN+UvDb0KC9JnGaBrCotUY\ncsK49cB1AL6VNNf6b08zLJflI3AuQMqjB1kmpa+tlqfGJyc8KuNRFwujdeLEM0aV\n6s3rs7G2GIk9fCPSFBoX3mLBIQvR6fhsXTgAtr4rhKHYuHigMGa2JWHravnyhFUQ\n1+9iAWgNo3esy4CTpYD6+I13fdldBOt4vS+hoepTL+z+xOEMC2JYSDcT9vg5/W25\nma/ku1xGFFLh51tGn4+kdiEF6meYzzrCi1PBs4qv/GMRPwY6theyVsQHu1wEcN7B\n4xlthFMUXdHyvqc6gxmIKthvtCpxCW+5BWJJlIAvqMD/Dpwq2pSmjEJfeJmALSHm\nVS57d4rwGI2gXDwXBqxfWMdh7EGlREobup/ljEQrlbt3TH7yjACnQgGwCnCrLlHl\nTzhVGrONPF1Kagg8oj9SOrjQgIJ7IbjK/QLQEWwNMz3Ywnhmc8ogrG2UuzJLhG3e\n/dLQwmpSnAXCGFPir6ZEz+mdUYHW3g3sYg38U6yetU+RaZ9DWsqVs74w5jS53vG0\nCy/IlVqL4M1wrUVorQyXOux4CI58O9ArbZ/xUEvVloKfD8CzqQdmO9erqyrrDhkL\n04CXKrboQ8djWpNk5MWWuQ==\n-----END ENCRYPTED PRIVATE KEY-----\n",
#       "passphrase": "320c004d1e36338160c91daf78695309"
#     }
#   },
#   "enterpriseID": "828720650"
# }

