class V2::AppealStatusSerializer < V2::AppealSerializer
  type :appeal

  def id
    object.appeal_status_id
  end

  attribute :linked_review_ids, key: :appeal_ids

  attribute :type do
    "original"
  end

  attribute :location do
    # to be implement
  end

  attribute :incomplete_history do
    false
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
    # to be implemented
  end

  attribute :issues do
    # to be implemented
    # will need to override method used
    # issues already exists in appeal
  end
end
