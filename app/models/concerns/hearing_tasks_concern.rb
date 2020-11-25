# frozen_string_literal: true

##
# Shared module for hearing related task models (e.g ScheduleHearingTask, AssignHearingDispositionTask)
##
module HearingTasksConcern
  extend ActiveSupport::Concern

  private

  def withdraw_hearing(parent)
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.withdraw_hearing!(appeal)
      nil
    elsif appeal.is_a?(Appeal)
      EvidenceSubmissionWindowTask.find_or_create_by!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end
  end
end
