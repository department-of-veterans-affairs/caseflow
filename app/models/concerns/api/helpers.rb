# frozen_string_literal: true

module Api::Helpers
  extend ActiveSupport::Concern

  def to_float(val)
    Float val
  rescue StandardError
    nil
  end

  # returns a valid int or nil. for avoiding to_i which fails with 0
  def to_int(val)
    its_octal = val.is_a?(String) && val[0] == "0"
    val = to_float val unless its_octal
    # to_float allows a float string to be converted to an int
    Integer val
  rescue StandardError
    nil
  end

  def join_present(*args)
    args.reject(&:blank?).join(" ")
  end

  def missing_keys(hash, expected_keys:)
    (expected_keys.is_a?(Array) ? expected_keys : expected_keys.keys).reject { |k| hash.key? k }
  end

  def extra_keys(hash, expected_keys:)
    hash.except(*(expected_keys.is_a?(Array) ? expected_keys : expected_keys.keys)).keys
  end
end
