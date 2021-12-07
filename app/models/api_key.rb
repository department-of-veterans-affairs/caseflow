# frozen_string_literal: true

require "digest"
require "securerandom"
require "base64"

class ApiKey < CaseflowRecord
  before_create :generate_key_string
  has_many :api_views

  # Value of the key string, only available during creation
  attr_accessor :key_string

  def self.authorize(key_string)
    find_by(key_digest: digest_key_string(key_string))
  end

  def self.digest_key_string(key_string)
    Base64.encode64(Digest::SHA256.digest(key_string))
  end

  private

  def generate_key_string
    self.key_string ||= SecureRandom.uuid.delete("-")
    self.key_digest = self.class.digest_key_string(key_string)
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: api_keys
#
#  id            :integer          not null, primary key
#  consumer_name :string           not null, indexed
#  key_digest    :string           not null, indexed
#  created_at    :datetime
#  updated_at    :datetime         indexed
#
