# frozen_string_literal: true

class Generators::CAVCDecision
  extend Generators::Base

  class << self
    def default_attrs
      { decision_date: Time.zone.now - 4.months }
    end

    def build(attrs = {})
      attrs[:appeal_vacols_id] ||= attrs.delete(:appeal).vacols_id

      ::CAVCDecision.new(default_attrs.merge(attrs)).tap do |cavc_decision|
        Fakes::CAVCDecisionRepository.cavc_decision_records ||= []
        Fakes::CAVCDecisionRepository.cavc_decision_records.push(cavc_decision)
      end
    end
  end
end
