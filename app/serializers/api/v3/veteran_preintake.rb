# frozen_string_literal: true

class Api::V3::VeteranPreintake
  include Api::V3::Concerns::Validation

  attr_reader :file_number

  def initialize(veteran_hash)
    hash? veteran_hash
    these_are_the_hash_keys? veteran_hash, keys: ["data"]

    data = veteran_hash["data"]
    hash? data, name_of_value: "data"
    these_are_the_hash_keys? data, keys: %w[type id], name_of_value: "data"
    
    type, id= data.values_at "type", "id"

    fail ArgumentError, "type must be Veteran" unless type == "Veteran"

    int_or_int_string? id, name_of_value: "id"
    @file_number = id.to_s
    unless /^\d{8,9}$/.match?(@file_number)
      fail ArgumentError, "file_number (id) must be a string of 8 or 9 digits"
    end
  end
end
