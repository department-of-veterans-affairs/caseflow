# frozen_string_literal: true

class Api::V3::External::EndProductEstablishmentSerializer
  include FastJsonapi::ObjectSerializer
  attributes :synced_status, :reference_id

  attribute :request_issues do |epe|
    epe.request_issues.map do |ri|
      ::Api::V3::External::RequestIssueSerializer.new(ri)
    end
  end
end
