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
end