# frozen_string_literal: true

# Interface for use with Events::DecisionReviewCreated::DecisionReviewCreatedParser
# to extract Veteran information
module Events::VeteranExtractorInterface
  def veteran_file_number
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_ssn
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_first_name
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_last_name
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_middle_name
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_participant_id
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_bgs_last_synced_at
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_name_suffix
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def veteran_date_of_death
    fail NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end
