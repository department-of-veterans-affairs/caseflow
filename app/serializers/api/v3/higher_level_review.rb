class Api::V3::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  set_id :uuid
  set_type 'HigherLevelReview' # FIXME fasjonapi is making first letter lower

  attribute :status do |obect|
    obect.fetch_status
  end

  attribute :aoj
end