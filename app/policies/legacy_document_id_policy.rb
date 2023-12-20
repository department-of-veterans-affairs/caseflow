# frozen_string_literal: true

class LegacyDocumentIdPolicy
  def initialize(user:, case_review:)
    @user = user
    @case_review = case_review
  end

  def editable?
    return false unless case_review && user

    [case_review.assigned_to_css_id, case_review.assigned_by_css_id].include?(user.css_id)
  end

  private

  attr_reader :user, :case_review
end
