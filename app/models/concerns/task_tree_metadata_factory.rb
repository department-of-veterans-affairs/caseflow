# frozen_string_literal: true

class TaskTreeMetadataFactory
  class TreeMetadata
    attr_accessor :rootlevel_tasks, # holds RootTask and root-level tasks that are not under that RootTask
                  :rows, # { task1=>{ "colKey1" => "strValue1", "colKey2" => "strValue2", ... }, task2=>{...} }
                  :max_name_length, # length of longest appeal/task label (including indenting) when formatted as a tree
                  :col_metadata, # hash of column metadata (widths and labels)
                  :appeal_heading_row # final string for the appeal row with column heading labels
  end

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def treemetadata(obj, col_keys, col_labels, func_hash)
    if obj.is_a?(Task)
      appeal_label_str = appeal_label_from_template(obj.appeal)
      rootlevel_tasks = [obj]
      starting_depth = 0
    else
      appeal_label_str = appeal_label_from_template(obj)
      rootlevel_tasks = appeal_children(obj)
      starting_depth = 1
    end

    max_name_length = rootlevel_tasks.map do |task|
      calculate_max_name_length(task, starting_depth)
    end.append(appeal_label_str.size).max

    # col_keys is used for hashes like rows, col_metadata, and func_hash
    TaskTreeMetadataFactory::TreeMetadata.new.tap do |md|
      md.rootlevel_tasks = rootlevel_tasks
      md.rows = build_rows(obj, func_hash)
      md.max_name_length = max_name_length
      md.col_metadata = derive_column_metadata(col_keys, md.rows.values, col_labels)
      md.appeal_heading_row = appeal_heading(appeal_label_str, md.max_name_length, md.col_metadata)
    end
  end

  def build_rows(obj, func_hash)
    # Use func_hash to populate returned hash with tasks as keys
    # tree_rows={ task1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, task2=>{...} }
    tree_rows = obj.is_a?(Task) ? obj.appeal.tasks : obj.tasks
    build_rows_from(tree_rows, func_hash)
  end

  def build_rows_from(task_rows, func_hash)
    task_rows.compact.each_with_object({}) do |task, rows_obj|
      rows_obj[task] = func_hash.each_with_object({}) do |(col_key, func), obj|
        obj[col_key] = begin
          func.call(task)&.to_s || ""
                       rescue StandardError
                         config.func_error_char
        end
      end
    end
  end

  def appeal_heading(appeal_label, max_name_length, columns)
    # returns string for appeal header row: appeal_label followed by column headings
    appeal_label = appeal_label.ljust(max_name_length, config.heading_fill_str)
    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    col_headings_justified = columns.map { |_key, col_obj| col_obj[:label].ljust(col_obj[:width]) }

    "#{appeal_label} " + config.col_sep + config.cell_margin_char +
      col_headings_justified.join(col_seperator_with_margins) +
      config.cell_margin_char + config.col_sep
  end

  #------------------------

  def appeal_label_from_template(appeal)
    config.appeal_label_template.call(appeal)
  end

  # number of characters TTY::Tree uses for indenting
  INDENT_SIZE = 4

  def calculate_max_name_length(task, depth = 0)
    task_label_length = (INDENT_SIZE * depth) + task.class.name.length
    task.children.map do |child|
      calculate_max_name_length(child, depth + 1)
    end.append(task_label_length).max
  end

  def appeal_children(appeal)
    roottask_ids = appeal.tasks.where(parent_id: nil).pluck(:id)
    # Can the following be expressed using `where` so that it returns an AssociationRelation of Tasks?
    task_ids = appeal.tasks.reject { |tsk| tsk.parent&.appeal_id == appeal.id }.pluck(:id) if config.show_all_tasks
    roottask_ids |= task_ids if task_ids
    Task.where(id: roottask_ids.compact.sort)
  end

  #------------------------

  def derive_column_metadata(col_keys, row_values, col_labels)
    # Calculate column widths using rows only (not column heading labels)
    calculate_maxwidths(col_keys, row_values).tap do |col_metadata|
      # Set labels using specified col_labels or create heading labels using config's heading_transform
      if col_labels
        configure_headings_using_labels(col_labels, col_metadata, col_keys)
      else
        configure_headings_using_transform(col_metadata)
      end

      update_col_widths_to_fit_col_labels(col_metadata)
    end
  end

  def calculate_maxwidths(keys, row_values)
    keys.each_with_object({}) do |key, col_md|
      max_col_width = row_values.map { |row| row[key]&.to_s&.size || 0 }.compact.max
      col_md[key] = { width: max_col_width || 0 }
    end
  end

  def configure_headings_using_labels(col_labels, col_metadata, col_keys)
    col_keys.zip(col_labels).each do |key, label|
      col_metadata[key][:label] = label
    end
  end

  def configure_headings_using_transform(col_metadata)
    transformer = config.heading_transform_funcs_hash[config.heading_transform]
    unless transformer
      Rails.logger.warn "Unknown heading transform: #{config.heading_transform}"
      transformer = config.heading_transform_funcs_hash[:symbol_headings]
    end

    col_metadata.each { |key, col_obj| col_obj[:label] = transformer.call(key, col_obj) }
  end

  def update_col_widths_to_fit_col_labels(col_metadata)
    col_metadata.each do |_key, col_obj|
      col_obj[:width] = [col_obj[:width], col_obj[:label].size].max
    end
  end
end
