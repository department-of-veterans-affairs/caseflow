# frozen_string_literal: true

class CreateJudgeAssignTasksForAppeals
  def initialize(appeals:, genpop:, judge:)
    @appeals = appeals
    @genpop = genpop
    @judge = judge
  end

  def call
    return [] if appeals.empty?

    appeals.map do |appeal|
      JudgeAssignTaskCreator.new(appeal: appeal, judge: judge, genpop: genpop).call
    end
  end

  private

  attr_reader :appeals, :genpop, :judge
end
