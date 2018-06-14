class AmaReview < ApplicationRecord
  include EstablishesEndProduct

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  self.abstract_class = true

  attr_reader :saving_review

  has_many :request_issues, as: :review_request
  has_many :claimants, as: :review_request

  def start_review!
    @saving_review = true
  end

  def create_claimants!(claimant_data:)
    claimants.destroy_all unless claimants.empty?
    claimants.create_from_intake_data!(claimant_data)
  end

  def remove_claimants!
    claimants.destroy_all
  end
end
