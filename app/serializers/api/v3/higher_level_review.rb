class Api::V3::HigherLevelReviewSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  set_id :uuid
end