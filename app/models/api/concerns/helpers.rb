# frozen_string_literal: true

module Api::Helpers
  extend ActiveSupport::Concern

  private

  # returns a valid int or nil. for avoiding to_i which fails with 0
  def to_int(val)
    Integer val
  rescue StandardError
    nil
  end

  def join_present(*args)
    args.reject(&:blank?).join(" ")
  end

  def missing_keys(hash, expected_keys:)
    expected_keys.filter? { |k| !hash.key? k }
  end

  def extra_keys(hash, expected_keys:)
    hash.except(*expected_keys).keys
  end
end
