# frozen_string_literal: true

class TaskTreeMetadata
  def initialize(obj, config, func_hash, col_labels)
    @obj = obj
    @config = config
    @func_hash = func_hash
    @col_labels = col_labels
  end

  # returns RootTask and root-level tasks that are not under that RootTask
  def rootlevel_tasks
    @rootlevel_tasks ||= @obj.is_a?(Task) ? [@obj] : appeal_children(@obj)
  end

  # length of longest appeal/task label (including indenting) when formatted as a tree
  def max_name_length
    @max_name_length ||= rootlevel_tasks.map do |task|
      calculate_max_name_length(task, starting_depth)
    end.append(appeal_label_str.size).max
  end

  # Use func_hash to populate returned hash with tasks as keys
  # Hashes func_hash, rows, and col_metadata all use the same keys
  # returns { task1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, task2=>{...} }
  def rows
    @rows ||= build_rows_from(@obj.is_a?(Task) ? @obj.appeal.tasks : @obj.tasks)
  end

  # hash of column metadata (widths and labels)
  def col_metadata
    @col_metadata ||= derive_column_metadata(@func_hash.keys, rows.values, @col_labels)
  end

  # final string for the appeal row with column heading labels
  def appeal_heading_row
    @appeal_heading_row ||= appeal_heading_str
  end

  private

  def appeal_label_str
    @appeal_label_str ||= config.appeal_label_template.call(@obj.is_a?(Task) ? @obj.appeal : @obj)
  end

  def starting_depth
    @obj.is_a?(Task) ? 0 : 1
  end

  attr_reader :config

  def build_rows_from(task_rows)
    task_rows.compact.each_with_object({}) do |task, rows_obj|
      rows_obj[task] = @func_hash.each_with_object({}) do |(col_key, func), row|
        row[col_key] = begin
          func.call(task)&.to_s || ""
                       rescue StandardError
                         config.func_error_char
        end
      end
    end
  end

  # returns string for appeal header row: appeal_label followed by column headings
  def appeal_heading_str
    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    col_headings_justified = col_metadata.values.map { |col_obj| col_obj[:label].ljust(col_obj[:width]) }

    heading_str = appeal_label_str.ljust(max_name_length, config.heading_fill_str)
    heading_str << " " + config.col_sep + config.cell_margin_char
    heading_str << col_headings_justified.join(col_seperator_with_margins)
    heading_str << config.cell_margin_char + config.col_sep
  end

  #------------------------

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
