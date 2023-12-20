# frozen_string_literal: true

class IntakeUserStats
  def initialize(user:, n_days:)
    @user = user
    @n_days = n_days
    @stats = {}
  end

  def call
    intakes_in_range.each do |intake|
      completed = intake[:day_completed].iso8601
      type = intake.detail_type.underscore.to_sym
      stats[completed] ||= { type => 0, date: completed }
      stats[completed][type] ||= 0
      stats[completed][type] += 1
    end
    stats.sort.map { |entry| entry[1] }.reverse
  end

  private

  attr_reader :user, :n_days, :stats

  def intakes_in_range
    Intake.select("intakes.*, date(completed_at) as day_completed")
      .where(user: user)
      .where("completed_at > ?", Time.zone.now.end_of_day - n_days.days)
      .where(completion_status: "success")
      .order("day_completed")
  end
end
