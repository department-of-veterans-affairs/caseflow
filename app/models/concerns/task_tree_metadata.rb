# frozen_string_literal: true

class TaskTreeMetadata
  def initialize(obj, config, func_hash, col_labels = nil)
    @obj = obj
    @config = config
    @func_hash = func_hash
    @col_labels = col_labels
  end

  # returns RootTask and root-level tasks (which are not under that RootTask)
  def rootlevel_tasks
    @rootlevel_tasks ||= @obj.is_a?(Task) ? [@obj] : appeal_children(@obj)
  end

  # length of longest appeal/task label (including indenting) when formatted as a tree
  def max_name_length
    @max_name_length ||= rootlevel_tasks.map do |task|
      calculate_max_name_length(task, @obj.is_a?(Task) ? 0 : 1)
    end.append(appeal_label_str.size).max
  end

  # Use func_hash to populate returned hash with tasks as keys
  # returns { task1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, task2=>{...} }
  # Hashes func_hash, rows, and col_metadata all use the same keys
  def rows
    @rows ||= (@obj.is_a?(Task) ? @obj.appeal.tasks : @obj.tasks).each_with_object({}) do |task, rows_obj|
      rows_obj[task] = @func_hash.each_with_object({}) do |(col_key, func), row|
        row[col_key] = begin
          func.call(task)&.to_s || ""
                       rescue StandardError
                         config.func_error_char
        end
      end
    end
  end

  # hash of column metadata, containing col widths and heading labels based on configuration and parameters
  def col_metadata
    @col_metadata ||= calculate_maxwidths(@func_hash.keys, rows.values).tap do |col_metadata|
      if @col_labels
        configure_headings_using_labels(@col_labels, col_metadata, @func_hash.keys)
      else
        configure_headings_using_transforms(col_metadata)
      end
      update_col_widths_to_fit_col_labels(col_metadata)
    end
  end

  # returns string for appeal header row: appeal_label followed by column headings
  def appeal_heading_row
    return @appeal_heading_row if @appeal_heading_row

    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    col_headings_justified = col_metadata.values.map { |col_obj| col_obj[:label].ljust(col_obj[:width]) }

    @appeal_heading_row = appeal_label_str.ljust(max_name_length, config.heading_fill_str)
    @appeal_heading_row << " " + config.col_sep + config.cell_margin_char
    @appeal_heading_row << col_headings_justified.join(col_seperator_with_margins)
    @appeal_heading_row << config.cell_margin_char + config.col_sep
  end

  private

  attr_reader :config

  def appeal_label_str
    @appeal_label_str ||= config.appeal_label_template.call(@obj.is_a?(Task) ? @obj.appeal : @obj)
  end

  # number of characters TTY::Tree uses for indenting
  INDENT_SIZE = 4

  # return the max length for strings of task names, considering tree depth indentation
  def calculate_max_name_length(task, depth = 0)
    task_label_length = (INDENT_SIZE * depth) + task.class.name.length
    task.children.map do |child|
      calculate_max_name_length(child, depth + 1)
    end.append(task_label_length).max
  end

  # return all root-level tasks that are considered part of this appeal
  def appeal_children(appeal)
    roottask_ids = appeal.tasks.where(parent_id: nil).pluck(:id)
    # in some tests, parent tasks are (erroneously) not in the same appeal
    task_ids = appeal.tasks.reject { |tsk| tsk.parent&.appeal_id == appeal.id }.pluck(:id) if config.show_all_tasks
    roottask_ids |= task_ids if task_ids
    Task.where(id: roottask_ids.compact.sort)
  end

  # calculate column widths using rows only (not column heading labels)
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

  def configure_headings_using_transforms(col_metadata)
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
