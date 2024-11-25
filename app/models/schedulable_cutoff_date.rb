# frozen_string_literal: true

# == SchedulableCutoffDate
#
# Cutoff dates contained within this table dictate if an AMA appeal is consider "schedulable",
# which means that a hearings coordinator can proceed with scheduling a hearing for it.
#
# Appeals are considered schedulable if it meets at least one of the following conditions:
# - They are legacy appeals
# - They have an AOD (advanced on docket) designation
# - They are CAVC remands
# - They are AMA appeals whose receipt dates are on or before the most recently entered cutoff date.
#
# Only users in the HearingsSupervisor organization are able to add cutoff dates.
#
# The most recently added value will determined if appeals appear as schedulable in the National Hearing Queue.
#
# If no user-provided cutoff dates exist then December 31, 2019 should be utilized whenever determining if AMA appeals
# are schedulable.
class SchedulableCutoffDate < CaseflowRecord
  # Returns the most recently added cutoff date if one exists.
  # @return [SchedulableCutoffDate, nil]
  scope :most_recently_added, -> { order(created_at: :desc).limit(1) }
end
