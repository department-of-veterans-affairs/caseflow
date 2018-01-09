class DraftDecision
  include ActiveModel::Model

  attr_accessor :vbms_id, :type, :docket_number, :issues, :due_date,
  attr_accessor :appeal_id, :veteran_full_name, :aod, :cavc, :due_at

  def type
    "DraftDecision"
  end

  def complete!
    # update VACOLS assignments
  end
end
