# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
class TaskTreeRenderer
  attr_reader :config

  class TreeRendererConfig
    attr_accessor :show_all_tasks, :highlight_char,
                  :default_atts,
                  :heading_transform, :heading_transform_funcs_hash,
                  :appeal_label_template,
                  :value_funcs_hash,
                  :include_border,
                  :col_sep, :top_chars, :bottom_chars, :heading_fill_str, :cell_margin_char
  end

  def initialize
    puts "===> Creating TaskTreeRenderer"
    @config = TreeRendererConfig.new.tap do |conf|
      conf.show_all_tasks = true
      conf.highlight_char = "*"
      conf.default_atts = [:id, :status, :ASGN_BY, :ASGN_TO, :updated_at]
      conf.heading_transform = :upcase_headings
      conf.heading_transform_funcs_hash = {
        symbol_headings: ->(key, _col_obj) { ":#{key}" },
        upcase_headings: ->(key, _col_obj) { key.upcase },
        clipped_upcase_headings: ->(key, col_obj) { key[0..[0, col_obj[:width] - 1].max].upcase }
      }
      conf.appeal_label_template = lambda { |appeal|
        docket = (defined?(appeal.docket_type) && appeal.docket_type) ||
                 (defined?(appeal.docket_name) && appeal.docket_name)
        "#{appeal.class.name} #{appeal.id} (#{docket}) "
      }
      conf.value_funcs_hash = {
        ASGN_BY: lambda { |task|
          TaskTreeRenderer.send_chain(task, [:assigned_by, :type])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_by, :name])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_by, :css_id])&.to_s || ""
        },
        ASGN_TO: lambda { |task|
          TaskTreeRenderer.send_chain(task, [:assigned_to, :type])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_to, :name])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_to, :css_id])&.to_s || ""
        }
      }
    end
    ansi
  end

  def ansi
    config.include_border = true
    config.col_sep = "│"
    config.top_chars = "┌──┐"
    config.bottom_chars = "└──┘"
    config.heading_fill_str = "─"
    config.cell_margin_char = " "
    config
  end

  def ascii
    config.include_border = true
    config.col_sep = "|"
    config.top_chars = "+--+"
    config.bottom_chars = "+--+"
    config.heading_fill_str = "-"
    config.cell_margin_char = " "
    config
  end

  def compact
    config.include_border = false
    config.col_sep = " "
    config.heading_fill_str = " "
    config.cell_margin_char = ""
    config
  end

  def as_string(obj, *atts, col_labels: nil, highlight: nil)
    task_tree_hash, metadata = tree_hash(obj, *atts, col_labels: col_labels, highlight: highlight)
    table = TTY::Tree.new(task_tree_hash).render
    table.prepend(metadata.appeal_heading_row + "\n") if obj.is_a? Task

    if config.include_border
      top_border(metadata.max_name_length, metadata.col_metadata) + "\n" +
        table + bottom_border(metadata.max_name_length, metadata.col_metadata)
    else
      table
    end
  end

  class TreeMetadata
    attr_accessor :col_keys, # column keys for hashes like rows, col_metadata, and func_hash
                  :rows, # { task1=>{ "colKey1" => "strValue1", "colKey2" => "strValue2", ... }, task2=>{...} }
                  :max_name_length, # length of longest appeal/task label (including indenting) when formatted as a tree
                  :col_metadata, # hash of column metadata (widths and labels)
                  :appeal_heading_row # final string for the appeal row with column heading labels
  end

  HIGHLIGHT_COL_KEY = " "

  def tree_hash(obj, *atts, col_labels: nil, highlight: nil)
    atts = config.default_atts unless atts.any?

    highlighted_task = obj
    highlighted_task = Task.find(highlight) if highlight
    atts = [HIGHLIGHT_COL_KEY] | atts if highlight

    appeal_label = appeal_label(obj.is_a?(Task) ? obj.appeal : obj)

    metadata = TreeMetadata.new
    metadata.col_keys = atts.map(&:to_s)
    metadata.rows = build_rows(obj, atts, highlighted_task)
    metadata.max_name_length = calculate_max_name_length(obj, appeal_label.size)
    metadata.col_metadata = derive_column_metadata(metadata.col_keys, metadata.rows.values, col_labels)
    metadata.appeal_heading_row = appeal_heading(appeal_label, metadata.max_name_length, metadata.col_metadata)

    ts = obj.is_a?(Task) ? structure_task(obj, metadata, 0) : structure_appeal(obj, metadata, 0)
    [ts, metadata]
  end

  private

  def appeal_label(appeal)
    config.appeal_label_template.call(appeal)
  end

  # number of characters TTY::Tree uses for indenting
  INDENT_SIZE = 4

  def calculate_max_name_length(obj, max_name_length = 0, depth = 0)
    children = obj.is_a?(Task) ? task_children(obj) : appeal_children(obj)
    max_name_length = [max_name_length, (INDENT_SIZE * depth) + obj.class.name.length].max
    children.map do |task|
      calculate_max_name_length(task, max_name_length, depth + 1)
    end.append(max_name_length).max
  end

  def structure_appeal(appeal, metadata, depth = 0)
    row_str = metadata.appeal_heading_row
    { row_str => appeal_children(appeal).map { |task| structure_task(task, metadata, depth + 1) } }
  end

  def structure_task(task, metadata, depth = 0)
    row_str = task_row(task, metadata.max_name_length, depth, metadata.col_metadata, metadata.rows[task])
    { row_str => task_children(task).map { |child| structure_task(child, metadata, depth + 1) } }
  end

  def task_children(task)
    task.children.order(:id)
  end

  def appeal_children(appeal)
    roottask_ids = appeal.tasks.where(parent_id: nil).order(:id).pluck(:id)
    # Can the following be expressed using `where` so that it returns an AssociationRelation of Tasks?
    task_ids = appeal.tasks.order(:id).reject { |tsk| tsk.parent&.appeal_id == appeal.id }.pluck(:id) if config.show_all_tasks
    roottask_ids |= task_ids if task_ids
    roottask_ids = roottask_ids.compact.sort
    Task.where(id: roottask_ids)
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

  def derive_column_metadata(col_keys, row_values, col_labels)
    # Calculate column widths using rows only (not column heading labels)
    col_metadata = TaskTreeRenderer.calculate_maxwidths(col_keys, row_values)

    # Set labels using specified col_labels or create heading labels using config's heading_transform
    if col_labels
      configure_headings_using_labels(col_labels, col_metadata, col_keys)
    else
      configure_headings_using_transform(col_metadata)
    end

    update_col_widths_to_fit_col_labels(col_metadata)
    col_metadata
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

  # hash of lambdas that return string of the cell value
  def derive_value_funcs_hash(atts, highlighted_obj = nil)
    atts.each_with_object({}) do |att, obj|
      if att.is_a?(Array)
        obj[att.to_s] = ->(task) { TaskTreeRenderer.send_chain(task, att)&.to_s || "" }
      elsif att == HIGHLIGHT_COL_KEY
        obj[HIGHLIGHT_COL_KEY] = ->(task) { (task == highlighted_obj) ? config.highlight_char : " " }
      elsif config.value_funcs_hash[att]
        obj[att.to_s] = config.value_funcs_hash[att]
      else
        obj[att.to_s] = ->(task) { task.send(att)&.to_s || "" }
      end
    end
  end

  class << self
    def calculate_maxwidths(keys, rows)
      keys.each_with_object({}) do |key, obj|
        max_value_size = rows.map do |row|
          row[key]&.size
        end.compact.max
        obj[key] = {
          width: max_value_size || 0
        }
      end
    end

    def send_chain(initial_obj, methods)
      methods.inject(initial_obj) do |obj, method|
        obj.respond_to?(method) ? obj.send(method) : nil
      end
    end
  end

  def top_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_border(col_metadata, config.top_chars)
  end

  def bottom_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_border(col_metadata, config.bottom_chars)
  end

  def write_border(columns, border_chars = "+-|+")
    dash = border_chars[1]
    margin = dash * config.cell_margin_char.size
    col_borders = columns.map { |_, col| dash * col[:width] }.join(margin + border_chars[2] + margin)
    border_chars[0] + margin + col_borders + margin + border_chars[3]
  end

  def build_rows(obj, atts, highlighted_obj = self)
    # Create func_hash based on atts
    # func_hash={ "colKey1"=>lambda(task), "colKey2"=>lambda2(task), ... }
    func_hash = derive_value_funcs_hash(atts, highlighted_obj)

    # Use func_hash to populate returned hash with tasks as keys
    # tree_rows={ task1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, task2=>{...} }
    tree_rows = obj.is_a?(Task) ? obj.appeal.tasks : obj.tasks
    build_rows_from(tree_rows, func_hash)
  end

  def build_rows_from(task_rows, func_hash)
    task_rows.compact.each_with_object({}) do |task, rows_obj|
      rows_obj[task] = func_hash.each_with_object({}) do |(col_key, func), obj|
        obj[col_key] = func.call(task)
      end
    end
  end

  def task_row(task, max_name_length, depth, columns, row)
    task.class.name.ljust(max_name_length - (INDENT_SIZE * depth)) + " " + tree_task_attributes(columns, row)
  end

  def tree_task_attributes(columns, row)
    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    cols_str = columns.map do |key, col_obj|
      value = row[key]
      value = "" if value.nil?
      value.ljust(col_obj[:width])
    end.compact.join(col_seperator_with_margins)
    config.col_sep + config.cell_margin_char + cols_str +
      config.cell_margin_char + config.col_sep
  end
end
