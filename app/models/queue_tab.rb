# frozen_string_literal: true

class QueueTab
  include ActiveModel::Model

  attr_accessor :assignee_name, :show_regional_office_column

  def to_hash
    {
      label: label,
      name: name,
      description: format(description, assignee_name),
      columns: columns,
      allow_bulk_assign: allow_bulk_assign?
    }
  end

  def label; end

  def name; end

  def description; end

  def columns; end

  def allow_bulk_assign?
    false
  end
end
