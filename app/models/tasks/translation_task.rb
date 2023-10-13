# frozen_string_literal: true

##
# After intake, a TranslationTask is automatically assigned to the Translation organization when a case originates
# from an RO in Puerto Rico or the Philippines because the VA assumes there are Veteran documents needing translation.
# Task can be manually assigned in other stages.

class TranslationTask < Task
  include CavcAdminActionConcern

  ## Tag to determine if this task is considered a blocking task for Legacy Appeal Distribution
  def self.legacy_blocking?
    true
  end

  def self.create_from_root_task(root_task)
    create!(assigned_to: Translation.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def self.create_from_parent(parent_task)
    create!(assigned_to: Translation.singleton, parent_id: parent_task.id, appeal: parent_task.appeal)
  end
end
