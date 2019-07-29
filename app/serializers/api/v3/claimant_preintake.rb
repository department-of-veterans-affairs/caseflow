# frozen_string_literal: true

class Api::V3::ClaimantPreintake
  include Api::V3::Concerns::Validation
  include Api::V3::Concerns::Helpers

  attr_reader :participant_id, :payee_code

  def initialize(claimant_hash)
    hash? claimant_hash
    these_are_the_hash_keys? claimant_hash, keys: ["data"]

    data = claimant_hash["data"]
    hash? data, name_of_value: "data"
    these_are_the_hash_keys? data, keys: %w[type id meta], name_of_value: "data"
    
    type, id, meta = data.values_at "type", "id", "meta"

    fail ArgumentError, "type must be Claimant" unless type == "Claimant"

    int_or_int_string? id, name_of_value: "id"
    @participant_id = to_int id

    hash? meta
    these_are_the_hash_keys? meta, keys: ["payeeCode"]
    payee_code = meta["payeeCode"].to_s
    payee_code? payee_code, name_of_value: "payeeCode"
    @payee_code = payee_code
  end
end
