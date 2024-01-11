# frozen_string_literal: true

class RemandReason < CaseflowRecord
  validates :post_aoj, inclusion: { in: [true, false] }, unless: :additional_remand_reasons_enabled?
  validates :code, inclusion: { in: Constants::AMA_REMAND_REASONS_BY_ID.values.map(&:keys).flatten }
  belongs_to :decision_issue

  private

  def additional_remand_reasons_enabled?
    FeatureToggle.enabled?(:additional_remand_reasons)
  end
end
