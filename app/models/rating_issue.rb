class RatingIssue
  include ActiveModel::Model

  attr_accessor :reference_id, :decision_text

  # If you change this method, you will need
  # to clear cache in prod for your changes to
  # take effect immediately.
  # See Veteran#cached_serialized_timely_ratings.
  def ui_hash
    {
      reference_id: reference_id,
      decision_text: decision_text
    }
  end

  def self.from_bgs_hash(data)
    new(
      reference_id: data[:rba_issue_id],
      decision_text: data[:decn_txt]
    )
  end
end
