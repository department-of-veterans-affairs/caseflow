# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRender
  mattr_accessor :treeconfig
  self.treeconfig = {
    include_border: true,
    col_sep: "│",
    top_chars: "┌──┐",
    bottom_chars: "└──┘",
    heading_fill_char: "─",
    cell_margin_char: " ",
    appeal_label_template: '#{self.class.name} #{id} (#{' \
                           "(defined?(docket_type) && docket_type) ||" \
                           "(defined?(docket_name) && docket_name)" \
                           "}) ",
    default_atts: [:id, :status, :assigned_to_type, :ASGN_BY, :ASGN_TO, :created_at, :updated_at],
    heading_transform: :upcase_headings,
    heading_transform_funcs_hash: {
      symbol_headings: ->(key, _col_obj) { ":#{key}" },
      upcase_headings: ->(key, _col_obj) { key.upcase },
      clipped_upcase_headings: ->(key, col_obj) { key[0..[0, col_obj[:width] - 1].max].upcase }
    },
    value_funcs_hash: {
      ASGN_BY: lambda { |task|
        send_chain(task, [:assigned_by, :type])&.to_s ||
          send_chain(task, [:assigned_by, :name])&.to_s ||
          send_chain(task, [:assigned_by, :css_id])&.to_s || ""
      },
      ASGN_TO: lambda { |task|
        send_chain(task, [:assigned_to, :type])&.to_s ||
          send_chain(task, [:assigned_to, :name])&.to_s ||
          send_chain(task, [:assigned_to, :css_id])&.to_s || ""
      }
    }
  }

  def self.ansi
    treeconfig[:include_border] = true
    treeconfig[:col_sep] = "│"
    treeconfig[:top_chars] = "┌──┐"
    treeconfig[:bottom_chars] = "└──┘"
    treeconfig[:heading_fill_char] = "─"
    treeconfig[:cell_margin_char] = " "
    treeconfig
  end

  def self.ascii
    treeconfig[:include_border] = true
    treeconfig[:col_sep] = "|"
    treeconfig[:top_chars] = "+--+"
    treeconfig[:bottom_chars] = "+--+"
    treeconfig[:heading_fill_char] = "-"
    treeconfig[:cell_margin_char] = " "
    treeconfig
  end

  def self.compact
    treeconfig[:include_border] = false
    treeconfig[:col_sep] = " "
    treeconfig[:heading_fill_char] = " "
    treeconfig[:cell_margin_char] = ""
    treeconfig
  end

  def tree(*atts, col_labels: nil, highlight: nil)
    atts = treeconfig[:default_atts] unless atts.any?
    # rows_hash = { task1=>{ "strCol1" => "strValue1", "strCol2" => "strValue2", ... }, task2=>{...} }
    highlight_obj = Task.find(highlight) if highlight
    rows_hash = build_rows(atts, highlight_obj)

    # Calculate column widths using rows only (not column heading labels)
    col_keys = atts.map(&:to_s)
    col_metadata = calculate_maxwidths(col_keys, rows_hash.values)

    # Set labels using specified col_labels or create heading labels using a transform
    if col_labels
      col_keys.zip(col_labels).each do |key, label|
        col_metadata[key][:label] = label
      end
    else
      col_metadata.each do |key, col_obj|
        transformer = treeconfig[:heading_transform_funcs_hash][treeconfig[:heading_transform]]
        puts "Unknown heading transform: #{treeconfig[:heading_transform]}" unless transformer
        col_obj[:label] = transformer.call(key, col_obj)
      end
    end

    update_col_widths_to_fit_col_labels(col_metadata)

    curr_appeal = is_a?(Task) ? appeal : self
    max_name_length = calculate_max_name_length(curr_appeal.eval_appeal_label.size)

    ts = tree_structure(col_metadata, rows_hash, max_name_length, 0)
    table = create_heading_if_self_is_a_task(col_metadata, max_name_length) + TTY::Tree.new(ts).render

    if treeconfig[:include_border]
      top_border(max_name_length, col_metadata) + "\n" +
        table + bottom_border(max_name_length, col_metadata)
    else
      table
    end
  end

  def create_heading_if_self_is_a_task(col_metadata, max_name_length)
    heading = appeal.appeal_heading(appeal_id, col_metadata, max_name_length) if is_a? Task
    heading&.concat("\n") || ""
  end

  def calculate_max_name_length(max_name_length = 0, depth = 0)
    max_name_length = [max_name_length, (INDENT_SIZE * depth) + self.class.name.length].max
    tree_children.map do |child|
      child.calculate_max_name_length(max_name_length, depth + 1)
    end.append(max_name_length).max
  end

  def tree_structure(columns, rows, max_name_length, depth = 0)
    row_str = if is_a?(Task)
                task_row(max_name_length, depth, columns, rows[self])
              else
                appeal_heading(id, columns, max_name_length)
              end
    { "#{row_str}": tree_children.map { |child| child.tree_structure(columns, rows, max_name_length, depth + 1) } }
  end

  def appeal_heading(_appeal_id, columns, max_name_length)
    # print appeal row: appeal_label followed by column headings
    appeal_label = eval_appeal_label.ljust(max_name_length, treeconfig[:heading_fill_char])
    col_seperator_with_margins = treeconfig[:cell_margin_char] + treeconfig[:col_sep] + treeconfig[:cell_margin_char]
    "#{appeal_label} " + treeconfig[:col_sep] + treeconfig[:cell_margin_char] +
      columns.map do |_key, col_obj|
        value = col_obj[:label]
        value.ljust(col_obj[:width])
      end.compact.join(col_seperator_with_margins) +
      treeconfig[:cell_margin_char] + treeconfig[:col_sep]
  end

  def eval_appeal_label
    eval('"' + treeconfig[:appeal_label_template] + '"')
  end

  class << self
    # hash of lambdas that return string of the cell value
    def derive_value_funcs_hash(atts, highlight_obj = nil)
      atts.each_with_object({}) do |att, obj|
        if att.is_a?(Array)
          obj[att.to_s] = ->(task) { send_chain(task, att)&.to_s || "" }
        elsif att == " "
          obj[" "] = ->(task) { (task == highlight_obj) ? "*" : " " }
        elsif treeconfig[:value_funcs_hash][att]
          obj[att.to_s] = treeconfig[:value_funcs_hash][att]
        else
          obj[att.to_s] = ->(task) { task.send(att)&.to_s || "" }
        end
      end
    end

    def send_chain(initial_obj, methods)
      methods.inject(initial_obj) do |obj, method|
        obj.respond_to?(method) ? obj.send(method) : nil
      end
    end
  end

  private

  INDENT_SIZE = 4

  def build_rows(atts, highlight_obj = self)
    # Create func_hash based on atts
    # func_hash={ "colKey1"=>lambda(task), "colKey2"=>lambda2(task), ... }
    func_hash = TaskTreeRender.derive_value_funcs_hash(atts, highlight_obj)

    # Use func_hash to populate returned hash with tasks as keys
    # { task1=>{ "strCol1" => "strValue1", "strCol2" => "strValue2", ... }, task2=>{...} }
    tree_rows = is_a?(Task) ? appeal.tasks : tasks
    build_rows_from(tree_rows, func_hash)
  end

  def build_rows_from(tasklist, func_hash)
    tasklist.compact.each_with_object({}) do |task, rows_obj|
      rows_obj[task] = func_hash.each_with_object({}) do |(col_key, func), obj|
        obj[col_key] = func.call(task)
      end
    end
  end

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

  def update_col_widths_to_fit_col_labels(col_metadata)
    col_metadata.each do |_key, col_obj|
      col_obj[:width] = [col_obj[:width], col_obj[:label].size].max
    end
  end

  def tree_children
    subs = is_a?(Task) ? children : tasks.where(parent_id: nil)
    subs.order(:id)
  end

  def task_row(max_name_length, depth, columns, row)
    self.class.name.ljust(max_name_length - (INDENT_SIZE * depth)) + " " + tree_task_attributes(columns, row)
  end

  def tree_task_attributes(columns, row)
    col_seperator_with_margins = treeconfig[:cell_margin_char] + treeconfig[:col_sep] + treeconfig[:cell_margin_char]
    cols_str = columns.map do |key, col_obj|
      value = row[key]
      value = "" if value.nil?
      value.ljust(col_obj[:width])
    end.compact.join(col_seperator_with_margins)
    treeconfig[:col_sep] + treeconfig[:cell_margin_char] + cols_str +
      treeconfig[:cell_margin_char] + treeconfig[:col_sep]
  end

  def top_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_divider(col_metadata, treeconfig[:top_chars])
  end

  def bottom_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_divider(col_metadata, treeconfig[:bottom_chars])
  end

  def write_divider(columns, border_chars = "+-|+")
    dash = border_chars[1]
    margin = dash * treeconfig[:cell_margin_char].size
    col_border = columns.map { |_, col| dash * col[:width] }.join(margin + border_chars[2] + margin)
    border_chars[0] + margin + col_border + margin + border_chars[3]
  end
end
