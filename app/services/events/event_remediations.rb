# frozen_string_literal: true

# Find all the Appeals/LegacyAppeals for the intersection of a Veteran and Power of Attorney.

class EventRemediations
  def initialize(pids:)
    @pids = pids
  end

  def call
    if analyze
      # Do something if we find remediations to run
    else
      # Do something if we didn't find remediations to run
    end
  end

  private

  # analyzes person and veteran for needed remediations
  def analyze
    @pids.each do |pid|
      event_audit = EventAudit.find_by(pid: pid)
      # do something
    end
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
