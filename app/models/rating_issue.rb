class RatingIssue
  include ActiveModel::Model

  attr_accessor :rba_issue_id, :decision_text

  def ui_hash
    {
      rba_issue_id: rba_issue_id,
      decision_text: decision_text
    }
  end

  def self.from_bgs_hash(data)
    new(
      rba_issue_id: data[:rba_issue_id],
      decision_text: data[:decn_txt]
    )
  end
end
