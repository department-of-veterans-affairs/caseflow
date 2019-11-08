# frozen_string_literal: true

class Api::V3::IssueSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = "Issue" #ContestableIssue?  Multiple serializers, need ids
  # can't use fastjson_api to serialize, need to skip ids
  # use contestableissue to pull this data (serialize method?)
  # should look like one of these:
  # {
  #   "type": "RequestIssue",
  #   "attributes": {
  #     "decisionText": "veteran status verified",
  #     "decisionDate": "2019-07-11",
  #     "category": "Eligibility | Veteran Status"
  #   }
  # },
  # {
  #   "type": "RequestIssue",
  #   "attributes": {
  #     "decisionIssueId": 22
  #   }
  # },
  # {
  #   "type": "RequestIssue",
  #   "attributes": {
  #     "ratingIssueId": "12345678",
  #     "legacyAppealId": "9876543210",
  #     "legacyAppealIssueId": 1
  #   }
  # }
end
