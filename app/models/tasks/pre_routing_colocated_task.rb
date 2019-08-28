# frozen_string_literal: true

##
# As of https://github.com/department-of-veterans-affairs/caseflow/pull/11467, FoiaColocatedTasks,
# MissingHearingTranscriptsColocatedTasks, and TranslationColocatedTasks automatically create children, route them to
# appropriate team, and hide the parent colocated task as they are never acted upon but still want to retain some of
# the ColocatedTask logic. This left many tasks in production without the expected child tasks hidden from their
# This subclass has been created to preserve the old logic for these tasks in production until they are all completed

class PreRoutingColocatedTask < ColocatedTask
  def self.label
    name
  end
end
