# frozen_string_literal: true

class AppealTaskHistory
  def initialize(appeal:)
    @appeal = appeal
  end

  def events
    @events ||= build_events
  end

  def summary
    events.map(&:summary)
  end

  private

  attr_reader :appeal

  def build_events
    # iterate through appeal.tasks.versions and build a single array
    # of changes in reverse chronological order (most recent first).
    # returns that array as TaskEvent objects
    appeal.tasks.map(&:versions)
      .flatten.map { |vers| TaskEvent.new(version: vers) }
      .sort_by { |event| [event.version.created_at, event.version.id] }.reverse
  end
end
