# frozen_string_literal: true

class DasDeprecation::CaseDistribution
  class << self
    def create_judge_assign_task(record, judge)
      legacy_appeal = LegacyAppeal.find_or_create_by_vacols_id(record["bfkey"])
      legacy_appeal.transaction do
        root_task = RootTask.find_or_create_by!(appeal: legacy_appeal)
        JudgeAssignTaskCreator.new(appeal: legacy_appeal, judge: judge, assigned_by_id: root_task.assigned_to.id).call

        yield if block_given?
      end
    end
  end
end
