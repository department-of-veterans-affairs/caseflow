# frozen_string_literal: true

class CorrespondenceQueueColumn < QueueColumn
  include ActiveModel::Model

  attr_accessor :filterable, :name

  def initialize(args)
    super
    @filterable ||= false
  end

  FILTER_OPTIONS = {
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name => :task_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name => :va_dor_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name => :date_completed_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name => :task_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name => :package_document_type_options
  }.freeze

  private

  def package_document_type_options(tasks)
    tasks.joins(:appeal).group(:nod).count.each_pair.map do |option, count|
      label = if option
                self.class.format_option_label(Constants.QUEUE_CONFIG.PACKAGE_DOC_TYPE_FILTER_OPTIONS.NOD, count)
              else
                self.class.format_option_label(Constants.QUEUE_CONFIG.PACKAGE_DOC_TYPE_FILTER_OPTIONS.NON_NOD, count)
              end
      self.class.filter_option_hash(option.to_s, label)
    end
  end

  # placeholder method because the function is required
  def va_dor_options(dummy)
    dummy
  end

  def date_completed_options(dummy)
    dummy
  end
end
