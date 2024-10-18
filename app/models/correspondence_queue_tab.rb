# frozen_string_literal: true

class CorrespondenceQueueTab < QueueTab
  def columns
    column_names.map { |column_name| CorrespondenceQueueColumn.from_name(column_name) }
  end

  def task_includes
    [
      { appeal: [:veteran] },
      :assigned_by,
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

  def column_names
    self.class.column_names
  end
end
