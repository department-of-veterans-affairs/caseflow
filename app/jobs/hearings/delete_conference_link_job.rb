# frozen_string_literal: true

class DeleteConferenceLinkJob < CaseflowJob
  queue_with_priority :low_priority

  def perform

  end

end
