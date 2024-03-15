# frozen_string_literal: true

module Events::DecisionReviewCreated::VeteranExtractorInterface
  def file_number
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def ssn
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def first_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def last_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def middle_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def participant_id
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def bgs_last_synced_at
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def name_suffix
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def date_of_death
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
