class V2::AppealStatusSerializer < V2::AppealSerializer
  type :appeal

  def id
    object.appeal_status_id
  end

  attribute :linked_review_ids, key: :appeal_ids

  attribute :type do
    # this does not apply to HLR
  end

  attribute :location do
    # to be implement
  end

  attribute :incomplete do
    false
  end

  attribute :type do
    "original"
  end

  attribute :aoj do
    "other"
  end

  attribute :aod do
    # to be implemented
  end

  attribute :docket do
    # to be implemented
  end

  attribute :events do
  end
end
