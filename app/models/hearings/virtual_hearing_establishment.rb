# frozen_string_literal: true

# Tracks the progress of the job responsible for creating
# the virtual hearing conference in Pexip, and sending out
# emails to the participants of the conference.
class VirtualHearingEstablishment < CaseflowRecord
  include Asyncable

  belongs_to :virtual_hearing

  # :nocov:
  # Implements Asyncable
  def veteran
    virtual_hearing.hearing.appeal&.veteran
  end

  # Implements Asyncable
  def asyncable_user
    virtual_hearing.created_by
  end
  # :nocov:
end
