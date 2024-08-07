# frozen_string_literal: true

class SearchQueryService::QueriedLegacyAppeal < SimpleDelegator
  def initialize(attributes:)
    @attributes = attributes
    @root_task_attributes = attributes.delete("root_task")
    @veteran_attributes = attributes.delete("veteran")

    super(legacy_appeal)
  end

  def veteran
    @veteran ||= Veteran.new.tap do |veteran|
      veteran.assign_attributes veteran_attributes
    end
  end

  def root_task
    @root_task ||= begin
      if root_task_attributes
        RootTask.new.tap do |root_task|
          root_task.assign_attributes root_task_attributes
        end
      end
    end
  end

  def claimant_participant_ids
    veteran.participant_id
  end

  private

  attr_reader :attributes, :root_task_attributes, :veteran_attributes

  def legacy_appeal
    @legacy_appeal ||= LegacyAppeal.new.tap do |appeal|
      appeal.assign_attributes(attributes)
    end
  end
end
