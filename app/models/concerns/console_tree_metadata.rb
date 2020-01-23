# frozen_string_literal: true

class ConsoleTreeMetadata
  def initialize(obj, config, func_hash, col_labels = nil)
    @obj = obj
    @config = config
    @value_funcs_hash = func_hash
    @col_labels = col_labels
  end

  # length of longest heading or row label (including indenting) when formatted as a tree
  def max_name_length
    @max_name_length ||= @obj.rootlevel_rows(config).map do |row|
      calculate_max_name_length(row, @obj == @obj.heading_object(config) ? 1 : 0)
    end.append(heading_label_str.size).max
  end

  # Use func_hash to populate returned hash with row objects as keys
  # returns { row1=>{ "colKey1" => "strValue1", "colKey1" => "strValue2", ... }, row2=>{...} }
  # Hashes func_hash, rows, and col_metadata all use the same keys
  def rows
    @rows ||= @obj.row_objects(config).each_with_object({}) do |rowObj, rows_hash|
      rows_hash[rowObj] = @value_funcs_hash.each_with_object({}) do |(col_key, func), row|
        row[col_key] = begin
          func.call(rowObj)&.to_s || ""
                       rescue StandardError
                         config.func_error_char
        end
      end
    end
  end

  # hash of column metadata, containing col widths and heading labels based on configuration and parameters
  def col_metadata
    @col_metadata ||= calculate_maxwidths(@value_funcs_hash.keys, rows.values).tap do |col_metadata|
      if @col_labels
        configure_headings_using_labels(@col_labels, col_metadata, @value_funcs_hash.keys)
      else
        configure_headings_using_transforms(col_metadata)
      end
      update_col_widths_to_fit_col_labels(col_metadata)
    end
  end

  # returns string for heading header row: heading_label_str followed by column headings
  def heading_row_str
    return @heading_row_str if @heading_row_str

    col_seperator_with_margins = config.cell_margin_char + config.col_sep + config.cell_margin_char
    col_headings_justified = col_metadata.values.map { |col_obj| col_obj[:label].ljust(col_obj[:width]) }

    @heading_row_str = heading_label_str.ljust(max_name_length, config.heading_fill_str)
    @heading_row_str << " " + config.col_sep + config.cell_margin_char
    @heading_row_str << col_headings_justified.join(col_seperator_with_margins)
    @heading_row_str << config.cell_margin_char + config.col_sep
  end

  private

  attr_reader :config

  def heading_label_str
    @heading_label_str ||= config.heading_label_template.call(@obj.heading_object(config))
  end

  # number of characters TTY::Tree uses for indenting
  INDENT_SIZE = 4

  # return the max length for strings of row labels, considering tree depth indentation
  def calculate_max_name_length(row, depth = 0)
    row_label_length = (INDENT_SIZE * depth) + row.row_label(config).length
    row.row_children(config).map do |child|
      calculate_max_name_length(child, depth + 1)
    end.append(row_label_length).max
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
