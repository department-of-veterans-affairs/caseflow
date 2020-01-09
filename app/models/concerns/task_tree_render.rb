# frozen_string_literal: true

# See instructions at https://github.com/department-of-veterans-affairs/caseflow/wiki/Task-Tree-Render
module TaskTreeRender
  mattr_accessor :treeconfig
  self.treeconfig = {
    show_all_tasks: true,
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
    task_tree_hash, metadata = tree_hash(*atts, col_labels: col_labels, highlight: highlight)
    table = TTY::Tree.new(task_tree_hash).render
    table.prepend(appeal.appeal_heading(metadata.max_name_length, metadata.col_metadata) + "\n") if is_a? Task

    if treeconfig[:include_border]
      TaskTreeRender.top_border(metadata.max_name_length, metadata.col_metadata) + "\n" +
        table +
        TaskTreeRender.bottom_border(metadata.max_name_length, metadata.col_metadata)
    else
      table
    end
  end

  class TreeMetadata
    attr_accessor :col_keys, # column keys for hashes like rows, col_metadata, and func_hash
                  :rows, # { task1=>{ "colKey1" => "strValue1", "colKey2" => "strValue2", ... }, task2=>{...} }
                  :max_name_length, # length of longest appeal/task label (including indenting) when formatted as a tree
                  :col_metadata # hash of column metadata (widths and labels)
  end

  def tree_hash(*atts, col_labels: nil, highlight: nil)
    atts = treeconfig[:default_atts] unless atts.any?

    highlighted_task = self
    highlighted_task = Task.find(highlight) if highlight
    atts = [" "] | atts if highlight

    curr_appeal = is_a?(Task) ? appeal : self

    metadata = TreeMetadata.new
    metadata.col_keys = atts.map(&:to_s)
    metadata.rows = build_rows(atts, highlighted_task)
    # pp metadata.rows
    metadata.max_name_length = calculate_max_name_length(curr_appeal.eval_appeal_label.size)
    TaskTreeRender.derive_column_metadata(metadata, col_labels)

    [tree_structure(metadata, 0), metadata]
  end

  def calculate_max_name_length(max_name_length = 0, depth = 0)
    max_name_length = [max_name_length, (INDENT_SIZE * depth) + self.class.name.length].max
    tree_children.map do |child|
      child.calculate_max_name_length(max_name_length, depth + 1)
    end.append(max_name_length).max
  end

  def tree_structure(metadata, depth = 0)
    row_str = if is_a?(Task)
                fail "Cannot find #{self} in #{metadata.rows.keys}" unless metadata.rows[self]

                task_row(metadata.max_name_length, depth, metadata.col_metadata, metadata.rows[self]) if metadata.rows[self]
              else
                appeal_heading(metadata.max_name_length, metadata.col_metadata)
              end
    { "#{row_str}": tree_children.map { |child| child.tree_structure(metadata, depth + 1) } }
  end

  def appeal_heading(max_name_length, columns)
    # returns string for appeal header row: appeal_label followed by column headings
    appeal_label = eval_appeal_label.ljust(max_name_length, treeconfig[:heading_fill_char])
    col_seperator_with_margins = treeconfig[:cell_margin_char] + treeconfig[:col_sep] + treeconfig[:cell_margin_char]
    col_headings_justified = columns.map { |_key, col_obj| col_obj[:label].ljust(col_obj[:width]) }

    "#{appeal_label} " + treeconfig[:col_sep] + treeconfig[:cell_margin_char] +
      col_headings_justified.join(col_seperator_with_margins) +
      treeconfig[:cell_margin_char] + treeconfig[:col_sep]
  end

  def eval_appeal_label
    eval('"' + treeconfig[:appeal_label_template] + '"')
  end

  class << self
    def derive_column_metadata(metadata, col_labels)
      # Calculate column widths using rows only (not column heading labels)
      col_metadata = calculate_maxwidths(metadata.col_keys, metadata.rows.values)

      # Set labels using specified col_labels or create heading labels using treeconfig's heading_transform
      if col_labels
        configure_headings_using_labels(col_labels, col_metadata, metadata.col_keys)
      else
        configure_headings_using_transform(col_metadata)
      end

      update_col_widths_to_fit_col_labels(col_metadata)
      metadata.col_metadata = col_metadata
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

    def configure_headings_using_labels(col_labels, col_metadata, col_keys)
      col_keys.zip(col_labels).each do |key, label|
        col_metadata[key][:label] = label
      end
    end

    def configure_headings_using_transform(col_metadata)
      transformer = treeconfig[:heading_transform_funcs_hash][treeconfig[:heading_transform]]
      unless transformer
        Rails.logger.warn "Unknown heading transform: #{treeconfig[:heading_transform]}"
        transformer = treeconfig[:heading_transform_funcs_hash][:symbol_headings]
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
          obj[att.to_s] = ->(task) { send_chain(task, att)&.to_s || "" }
        elsif att == " "
          obj[" "] = ->(task) { (task == highlighted_obj) ? "*" : " " }
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

    def top_border(max_name_length, col_metadata)
      "".ljust(max_name_length) + " " + write_border(col_metadata, treeconfig[:top_chars])
    end

    def bottom_border(max_name_length, col_metadata)
      "".ljust(max_name_length) + " " + write_border(col_metadata, treeconfig[:bottom_chars])
    end

    def write_border(columns, border_chars = "+-|+")
      dash = border_chars[1]
      margin = dash * treeconfig[:cell_margin_char].size
      col_borders = columns.map { |_, col| dash * col[:width] }.join(margin + border_chars[2] + margin)
      border_chars[0] + margin + col_borders + margin + border_chars[3]
    end
  end

  private

  INDENT_SIZE = 4

  def build_rows(atts, highlighted_obj = self)
    # Create func_hash based on atts
    # func_hash={ "colKey1"=>lambda(task), "colKey2"=>lambda2(task), ... }
    func_hash = TaskTreeRender.derive_value_funcs_hash(atts, highlighted_obj)

    # Use func_hash to populate returned hash with tasks as keys
    # { task1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, task2=>{...} }
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

  def tree_children
    subs = is_a?(Task) ? children.order(:id) : tasks.where(parent_id: nil)
    child_ids = subs.pluck(:id)
    # TODO: can the following be expressed using `where`(?) so that it returns an AssociationRelation of Tasks?
    task_ids = tasks.order(:id).reject { |t| t.parent&.appeal_id == id }.pluck(:id) if treeconfig[:show_all_tasks] && !is_a?(Task)
    child_ids |= task_ids if task_ids
    child_ids = child_ids.compact.sort
    Task.where(id: child_ids)
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
end
