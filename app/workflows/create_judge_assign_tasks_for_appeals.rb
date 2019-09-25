# frozen_string_literal: true

class CreateJudgeAssignTasksForAppeals
  def initialize(appeals:, judge:)
    @appeals = appeals
    @judge = judge
  end

  def call
    return [] if appeals.empty?

    appeals.map do |appeal|
      JudgeAssignTaskCreator.new(appeal: appeal, judge: judge).call
    end
  end

  private

  attr_reader :appeals, :judge
end
