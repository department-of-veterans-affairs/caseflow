# frozen_string_literal: true

class QueueTab
  include ActiveModel::Model

  #             string          boolean                       boolean                   boolean
  attr_accessor :assignee_name, :show_regional_office_column, :show_reader_link_column, :allow_bulk_assign

  # TODO: Do we want to do any validation of inputs?
  # def initialize(args); end

  def to_hash
    {
      label: label,
      name: name,
      description: format(description, assignee_name),
      # Compact to account for possibly absent columns.
      columns: columns.compact,
      allow_bulk_assign: allow_bulk_assign?
    }
  end

  # TODO: Raise errors if these are not defined?
  # TODO: Make this an abstract class that specific tabs have to implement?
  def label; end

  def name; end

  def description; end

  def columns; end

  def allow_bulk_assign?
    false
  end
end
