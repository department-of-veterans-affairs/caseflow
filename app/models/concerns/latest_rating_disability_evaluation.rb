# frozen_string_literal: true

module LatestRatingDisabilityEvaluation
  extend ActiveSupport::Concern

  class_methods do
    def latest_disability_evaluation(disability)
      latest = Array.wrap(disability[:disability_evaluations] || disability[:disability_evaluation])
        .max_by{ |dis_eval| dis_eval[:conv_begin_dt] || dis_eval[:begin_dt] || dis_eval[:dis_dt] }

      latest || {}
    end
  end
end
