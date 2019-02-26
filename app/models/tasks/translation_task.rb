##
# Task to track when documents are submitted that need to be translated.

class TranslationTask < GenericTask
  def self.create_from_root_task(root_task)
    create!(assigned_to: Translation.singleton, parent_id: root_task.id, appeal: root_task.appeal)
  end
end
