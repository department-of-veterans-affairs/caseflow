class AmaDocumentIdPolicy
  def initialize(user:, case_review:)
    @user = user
    @case_review = case_review
  end

  def editable?
    return false unless case_review && user

    [case_review.attorney_id, case_review.reviewing_judge_id].include?(user.id)
  end

  private

  attr_reader :user, :case_review
end
