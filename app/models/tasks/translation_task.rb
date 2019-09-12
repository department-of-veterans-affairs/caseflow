# frozen_string_literal: true

##
# Task automatically assigned after intake to the Translation organization when a case originates
# from an RO in Puerto Rico or the Phillipines.

class TranslationTask < Task
  def self.create_from_root_task(root_task)
    create!(assigned_to: Translation.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end

  def self.create_from_parent(parent_task)
    create!(assigned_to: Translation.singleton, parent_id: parent_task.id, appeal: parent_task.appeal)
  end
end
