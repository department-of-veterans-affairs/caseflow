# frozen_string_literal: true

# ephemeral class used for caching Rating Decisions

class RatingDecision
  include ActiveModel::Model

  attr_accessor :type_name, :rating_sequence_number, :disability_id, :diagnostic_text, :profile_date

  class << self
    def from_bgs_hash(bgs_data)
      new(bgs_data)
    end
  end

  def ui_hash
    serialize
  end

  # If you change this method, you will need to clear cache in prod for your changes to
  # take effect immediately. See DecisionReview#cached_serialized_ratings
  def serialize
    to_h
  end
end
