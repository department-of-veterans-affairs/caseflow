# frozen_string_literal: true

class TaskTreeRenderer
  attr_reader :config

  # See descriptions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
  class TreeRendererConfig
    attr_accessor :show_all_tasks, :highlight_char,
                  :default_atts,
                  :heading_transform, :heading_transform_funcs_hash,
                  :appeal_label_template,
                  :value_funcs_hash,
                  :include_border,
                  :col_sep, :top_chars, :bottom_chars,
                  :heading_fill_str, :cell_margin_char, :func_error_char
  end

  def initialize
    @config = TreeRendererConfig.new.tap do |conf|
      conf.show_all_tasks = true
      conf.highlight_char = "*"
      conf.func_error_char = "-"
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
            TaskTreeRenderer.send_chain(task, [:assigned_by, :css_id])&.to_s
        },
        ASGN_TO: lambda { |task|
          TaskTreeRenderer.send_chain(task, [:assigned_to, :type])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_to, :name])&.to_s ||
            TaskTreeRenderer.send_chain(task, [:assigned_to, :css_id])&.to_s
        }
      }
    end
    ansi
  end

  class << self
    def send_chain(initial_obj, methods)
      methods.inject(initial_obj) do |obj, method|
        obj.respond_to?(method) ? obj.send(method) : nil
      end
    end
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

  def tree_str(obj, *atts, **kwargs)
    fail "TTY::Tree does not work when config.col_sep='/'" if config.col_sep == "/"

    task_tree_hash, metadata = tree_hash(obj, *atts, **kwargs)
    table = TTY::Tree.new(task_tree_hash).render
    table.prepend(metadata.appeal_heading_row + "\n") if obj.is_a? Task

    if config.include_border
      top_border(metadata.max_name_length, metadata.col_metadata) + "\n" +
        table + bottom_border(metadata.max_name_length, metadata.col_metadata)
    else
      table
    end
  end

  HIGHLIGHT_COL_KEY = " "

  def tree_hash(obj, *atts, col_labels: nil, highlight: nil)
    atts = config.default_atts unless atts.any?
    atts = [HIGHLIGHT_COL_KEY] | atts if highlight

    highlighted_task = obj
    highlighted_task = Task.find(highlight) if highlight

    # func_hash={ "colKey1"=>lambda(task), "colKey2"=>lambda2(task), ... }
    func_hash = derive_value_funcs_hash(atts, highlighted_task)

    metadata = TaskTreeMetadataFactory.new(config).treemetadata(obj, atts.map(&:to_s), col_labels, func_hash)
    ts = obj.is_a?(Task) ? structure_task(obj, metadata) : structure_appeal(metadata)
    [ts, metadata]
  end

  private

  # hash of lambdas that return string of the cell value
  def derive_value_funcs_hash(atts, highlighted_task)
    {}.tap do |funcs_hash|
      atts.each do |att|
        if att.is_a?(Array)
          funcs_hash[att.to_s] = ->(task) { TaskTreeRenderer.send_chain(task, att)&.to_s || "" }
        elsif att == HIGHLIGHT_COL_KEY
          funcs_hash[HIGHLIGHT_COL_KEY] = ->(task) { (task == highlighted_task) ? config.highlight_char : " " }
        elsif config.value_funcs_hash[att]
          funcs_hash[att.to_s] = config.value_funcs_hash[att]
        else
          funcs_hash[att.to_s] = ->(task) { task.send(att)&.to_s || "" }
        end
      end
    end
  end

  def structure_appeal(metadata, depth = 0)
    row_str = metadata.appeal_heading_row
    { row_str => metadata.rootlevel_tasks.map { |task| structure_task(task, metadata, depth + 1) } }
  end

  def structure_task(task, metadata, depth = 0)
    row_str = task_row(task, metadata.max_name_length, depth, metadata.col_metadata, metadata.rows[task])
    { row_str => task.children.order(:id).map { |child| structure_task(child, metadata, depth + 1) } }
  end

  def task_row(task, max_name_length, depth, columns, row)
    task.class.name.ljust(max_name_length - (TaskTreeMetadataFactory::INDENT_SIZE * depth)) +
      " " + tree_task_attributes(columns, row)
  end

  def tree_task_attributes(columns, row)
    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    values_str = columns.map do |key, col_obj|
      value = row[key]
      value.ljust(col_obj[:width])
    end.compact.join(col_seperator_with_margins)

    config.col_sep + config.cell_margin_char + values_str + config.cell_margin_char + config.col_sep
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
    col_sep = config.col_sep.empty? ? "" : border_chars[2].center(config.col_sep.size)
    col_borders = columns.map { |_, col| dash * col[:width] }.join(margin + col_sep + margin)

    (config.col_sep.empty? ? "" : border_chars[0]) +
      margin + col_borders + margin +
      (config.col_sep.empty? ? "" : border_chars[3])
  end
end
