# frozen_string_literal: true

class CorrespondenceQueueTab < QueueTab
  def columns
    column_names.map do |column_name|
      CorrespondenceQueueColumn.new(name: column_name)
    end
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

  def default_sorting_column
    CorrespondenceQueueColumn.from_name(Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name)
  end
end
