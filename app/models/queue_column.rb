# frozen_string_literal: true

class QueueColumn
  include ActiveModel::Model

  class << self
    def from_name(column_name)
      column = subclasses.find { |subclass| subclass.column_name == column_name }
      fail(Caseflow::Error::InvalidTaskTableColumn, column_name: column_name) unless column

      column
    end

    def column_name; end

    def sorting_table
      Task.table_name
    end

    def sorting_columns
      %w[created_at]
    end
  end
end

require_dependency "appeal_type_column"
require_dependency "case_details_link_column"
require_dependency "days_on_hold_column"
require_dependency "days_waiting_column"
require_dependency "docket_number_column"
require_dependency "document_count_reader_link_column"
require_dependency "hearing_badge_column"
require_dependency "issue_count_column"
require_dependency "regional_office_column"
require_dependency "task_assignee_column"
require_dependency "task_assigner_column"
require_dependency "task_closed_date_column"
require_dependency "task_due_date_column"
require_dependency "task_hold_length_column"
require_dependency "task_type_column"
