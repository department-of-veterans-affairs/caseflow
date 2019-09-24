# frozen_string_literal: true

class AppealTaskHistory
  def initialize(appeal:)
    @appeal = appeal
  end

  def events
    @events ||= build_events
  end

  private

  attr_reader :appeal

  def build_events
    # iterate through appeal.tasks.versions and build a single array
    # of changes in reverse chronological order (most recent first).
    # returns that array as TaskEvent objects
    appeal.tasks.map(&:versions)
      .flatten.map { |vers| TaskEvent.new(version: vers) }
      .sort { |ev_a, ev_b| ev_b.created_at <=> ev_a.created_at }
  end
end
