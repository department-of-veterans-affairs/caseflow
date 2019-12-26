# frozen_string_literal: true

module TaskTreeRender
  # extend ActiveSupport::Concern

  mattr_accessor :config
  @@config = {
    include_border: true,
    col_sep: "│",
    top_chars: "┌──┐",
    bottom_chars: "└──┘",
    heading_fill_char: "─",
    cell_margin_char: " ",
    appeal_label_template: 'Appeal #{id} (#{' \
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
    builtin_value_funcs_hash: {
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
    @@config[:include_border] = true
    @@config[:col_sep] = "│"
    @@config[:top_chars] = "┌──┐"
    @@config[:bottom_chars] = "└──┘"
    @@config[:heading_fill_char] = "─"
    @@config
  end

  def self.ascii
    @@config[:include_border] = true
    @@config[:col_sep] = "|"
    @@config[:top_chars] = "+--+"
    @@config[:bottom_chars] = "+--+"
    @@config[:heading_fill_char] = "-"
    @@config
  end

  def self.compact
    @@config[:include_border] = false
    @@config[:col_sep] = " "
    @@config[:heading_fill_char] = "-"
    @@config[:cell_margin_char] = ""
    @@config
  end

  def tree_ex1
    tree(:id, :status, :assigned_to_type, "ASGN_TO_TYPE", :ASGN_BY, :ASGN_TO,
         user_func_hash: {
           "ASGN_TO_TYPE" => ->(task) { TaskTreeRender.send_chain(task, [:assigned_to, :type])&.to_s || "" }
         })
  end

  # puts Appeal.find(3).tree
  # puts Task.find(8).tree
  def tree_ex2
    atts = [:id, :status, :assigned_to_type, :parent_id, [:assigned_to, :type], :created_at, :updated_at]
    col_labels = ["\#", "Status", "Assign2Type", "P_ID", "ASGN_TO", "Created", "Updated"]
    tree(*atts, col_labels: col_labels)
  end

  def tree(*atts, user_func_hash: {}, col_labels: nil)
    atts = @@config[:default_atts] unless atts.any?
    col_keys = atts.map(&:to_s)

    # Create func_hash based on atts
    # func_hash={ "colKey1"=>lambda(task), "colKey2"=>lambda2(task), ... }
    func_hash = TaskTreeRender.value_funcs_hash(atts, self).merge(user_func_hash)

    # Use func_hash to populate rows hash with same keys as func_hash
    # rows={ task1=>{ "strCol1" => "strValue1", "strCol2" => "strValue2", ... }, task2=>{...} }
    tree_rows = is_a?(Task) ? appeal.tasks : tasks
    rows = build_rows_from(tree_rows, func_hash)

    # Calculate column widths using rows only (not column header labels)
    col_metadata = calculate_maxwidths(col_keys, rows.values)

    # Set labels from specified col_labels or create heading labels using a transform
    if col_labels
      col_keys.zip(col_labels).each do |key, label|
        col_metadata[key][:label] = label
      end
    else
      col_metadata.each do |key, col_obj|
        transformer = @@config[:heading_transform_funcs_hash][@@config[:heading_transform]]
        puts "Unknown heading transform: #{@@config[:heading_transform]}" unless transformer
        col_obj[:label] = transformer.call(key, col_obj)
      end
    end

    # Update col_widths to accommodate column labels
    col_metadata.each do |_key, col_obj|
      col_obj[:width] = [col_obj[:width], col_obj[:label].size].max
    end

    curr_appeal = is_a?(Task) ? appeal : self
    max_name_length = calculate_max_name_length(curr_appeal.eval_appeal_label.size)

    heading = appeal.appeal_heading(appeal_id, col_metadata, max_name_length) if is_a? Task
    ts = tree_structure(col_metadata, rows, max_name_length, 0)
    table = (heading&.concat("\n") || "") + TTY::Tree.new(ts).render

    if @@config[:include_border]
      top_border(max_name_length, col_metadata) + "\n" +
        table + bottom_border(max_name_length, col_metadata)
    else
      table
    end
  end

  INDENT_SIZE = 4

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
    # print appeal row: appeal_label followed by column headers
    appeal_label = eval_appeal_label.ljust(max_name_length, @@config[:heading_fill_char])
    "#{appeal_label} " + @@config[:col_sep] + @@config[:cell_margin_char] +
      columns.map do |key, _col_obj|
        value = columns[key][:label]
        value.ljust(columns[key][:width])
      end.compact.join(@@config[:cell_margin_char] + @@config[:col_sep] + @@config[:cell_margin_char]) +
      @@config[:cell_margin_char] + @@config[:col_sep]
  end

  def eval_appeal_label
    eval('"' + @@config[:appeal_label_template] + '"')
  end

  class << self
    # hash of lambdas that return string of cell value
    def value_funcs_hash(atts, highlight_obj = nil)
      atts.each_with_object({}) do |att, obj|
        if att.is_a?(Array)
          obj[att.to_s] = ->(task) { send_chain(task, att)&.to_s || "" }
        elsif att == " "
          obj[" "] = ->(task) { (task == highlight_obj) ? "*" : " " }
        elsif @@config[:builtin_value_funcs_hash][att]
          obj[att.to_s] = @@config[:builtin_value_funcs_hash][att]
        else
          obj[att.to_s] = ->(task) { task.send(att)&.to_s || "" }
        end
      end
    end

    def send_chain(obj, arr)
      arr.inject(obj) do |o, a|
        o.respond_to?(a) ? o.send(a) : nil
      end
    end
  end

  private

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
        width: max_value_size
      }
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
    @@config[:col_sep] + @@config[:cell_margin_char] +
      columns.map do |key, _col_obj|
        value = row[key]
        value = "" if value.nil?
        value.ljust(columns[key][:width])
      end.compact.join(@@config[:cell_margin_char] + @@config[:col_sep] + @@config[:cell_margin_char]) +
      @@config[:cell_margin_char] + @@config[:col_sep]
  end

  def top_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_divider(col_metadata, @@config[:top_chars])
  end

  def bottom_border(max_name_length, col_metadata)
    "".ljust(max_name_length) + " " + write_divider(col_metadata, @@config[:bottom_chars])
  end

  def write_divider(columns, col_seps = "+-|+")
    dash = col_seps[1]
    margin = dash * @@config[:cell_margin_char].size
    col_border = columns.map { |_, g| dash * g[:width] }.join(margin + col_seps[2] + margin)
    col_seps[0] + margin + col_border + margin + col_seps[3]
  end
end
