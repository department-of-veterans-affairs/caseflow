# frozen_string_literal: true

class ETL::JudgeCaseReviewSyncer < ETL::Syncer
  def origin_class
    ::JudgeCaseReview
  end

  def target_class
    ETL::JudgeCaseReview
  end
end
