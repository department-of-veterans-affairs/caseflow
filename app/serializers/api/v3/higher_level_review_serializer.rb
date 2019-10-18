class Api::V3::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  set_id :uuid
  set_type 'HigherLevelReview' # FIXME fasjonapi is making first letter lower

  attribute :status do |object|
    object.fetch_status
  end

  attributes :aoj, :description, :benefit_type, :receipt_date, :informal_conference, :same_office, :legacy_opt_in_approved
  attribute :program_area, &:program
  attribute :alerts
  attribute :events

  has_one :veteran do |object|
    object.veteran
  end

  has_one :claimant do |object|
    # DecisionReview has multiple claimants, but intakes only support one
    object.claimants.first
  end
  # has_many :decision_issues do |object|
  #   object.fetch_all_decision_issues
  # end
  # has_many :request_issues do |object|
  #   object.request_issues_ui_hash
  # end
end