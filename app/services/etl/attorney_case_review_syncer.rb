# frozen_string_literal: true

class ETL::AttorneyCaseReviewSyncer < ETL::Syncer
  def origin_class
    ::AttorneyCaseReview
  end

  def target_class
    ETL::AttorneyCaseReview
  end
end
