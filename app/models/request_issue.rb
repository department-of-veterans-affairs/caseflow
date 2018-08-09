class RequestIssue < ApplicationRecord
  belongs_to :review_request, polymorphic: true
  has_many :decision_issues

  def self.rated
    where.not(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
      .or(where(issue_category: "Unknown issue category"))
  end

  def self.nonrated
    where(rating_issue_reference_id: nil, rating_issue_profile_date: nil)
      .where.not(issue_category: [nil, "Unknown issue category"])
  end

  def self.create_from_intake_data!(data)
    create!(
      rating_issue_reference_id: data[:reference_id],
      rating_issue_profile_date: data[:profile_date],
      description: data[:decision_text] || data[:description],
      decision_date: data[:decision_date],
      issue_category: data[:issue_category]
    )
  end
end
