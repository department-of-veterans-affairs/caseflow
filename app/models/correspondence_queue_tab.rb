# frozen_string_literal: true

class CorrespondenceQueueTab < QueueTab
  def columns
    column_names.map { |column_name| CorrespondenceQueueColumn.from_name(column_name) }
  end

  def task_includes
    [
      { appeal: [:package_document_type] },
      :assigned_by,
      :assigned_to,
      :children,
      :parent
    ]
  end

  # :reek:UtilityFunction
  def default_sorting_column
    CorrespondenceQueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name)
  end

  # If you don't create your own tab name it will default to the tab defined in QueueTab
  def self.from_name(tab_name)
    tab = descendants.find { |subclass| subclass.tab_name == tab_name }
    fail(Caseflow::Error::InvalidTaskTableTab, tab_name: tab_name) unless tab

    tab
  end


  def self.serialize_columns
    [
      Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name,
      Constants.QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name,
      Constants.QUEUE_CONFIG.COLUMNS.ACTION_TYPE.name,
      Constants.QUEUE_CONFIG.COLUMNS.NOTES.name,
      Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name,
    ]
  end
end
