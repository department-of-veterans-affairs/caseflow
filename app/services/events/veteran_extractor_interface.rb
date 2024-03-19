# frozen_string_literal: true

# Interface for use with Events::DecisionReviewCreated::DecisionReviewCreatedParser
# to extract Veteran information
module Events::VeteranExtractorInterface
  def veteran_file_number
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_ssn
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_first_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_last_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_middle_name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_participant_id
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_bgs_last_synced_at
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_name_suffix
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_date_of_death
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
