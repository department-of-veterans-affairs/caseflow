# frozen_string_literal: true

class Api::ClaimantPreintake
  include Api::Validation

  attr_reader :participant_id, :payee_code

  def initialize(options)
    these_are_the_hash_keys? options, keys: %w[participant_id payee_code]
    @participant_id, @payee_code = options.values_at "participant_id", "payee_code"
    is_string? participant_id, key: :participant
    is_payee_code? payee_code, key: :payee_code
  end
end
