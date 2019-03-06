# frozen_string_literal: true

class Idt::Token
  VALID_TOKENS_KEY = "valid_tokens_key"
  ONE_TIME_KEYS_KEY = "one_time_keys_key"
  # 7 day validity window.
  TOKEN_VALIDITY_IN_SECONDS = 60 * 60 * 24 * 7

  def self.generate_one_time_key_and_proposed_token
    one_time_key = SecureRandom.hex(64)
    token = SecureRandom.hex(64)

    # Associate key and token, so we can later use the one time key
    # to activate the token.
    client.set(ONE_TIME_KEYS_KEY + one_time_key, token)

    [one_time_key, token]
  end

  def self.activate_proposed_token(one_time_key, css_id)
    token = client.get(ONE_TIME_KEYS_KEY + one_time_key)

    fail Caseflow::Error::InvalidOneTimeKey unless token && token.length == 128

    # Remove the one_time_key/token association to ensure it isn't used again,
    # and move the token to the valid tokens list for the validity period.
    client.del(ONE_TIME_KEYS_KEY + one_time_key)
    client.set(VALID_TOKENS_KEY + token, css_id)
    client.expire(VALID_TOKENS_KEY + token, TOKEN_VALIDITY_IN_SECONDS)

    true
  end

  def self.active?(token)
    # check if token is in valid list and return boolean
    client.exists(VALID_TOKENS_KEY + token)
  end

  def self.associated_css_id(token)
    client.get(VALID_TOKENS_KEY + token)
  end

  def self.client
    # Use separate Redis namespace for test to avoid conflicts between test and dev environments
    namespace = Rails.env.test? ? :idt_test : :idt
    @client ||= Redis::Namespace.new(namespace, redis: redis)
  end

  def self.redis
    @redis ||= Redis.new(url: Rails.application.secrets.redis_url_cache)
  end
end
