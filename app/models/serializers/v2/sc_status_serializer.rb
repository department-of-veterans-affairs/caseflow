class V2::SCStatusSerializer < V2::AppealSerializer
  type :supplemental_claim

  def id
    object.review_status_id
  end

  attribute :linked_review_ids, key: :appeal_ids

  attribute :type do
    # this does not apply to SC
  end

  attribute :location do
    # for SC will always be aoj
    "aoj"
  end

  attribute :incomplete_history do
    false
  end

  attribute :aod do
    # does not apply to SC
  end

  attribute :docket do
    # doesn't apply to SC
  end

  attribute :events do
  end
end
