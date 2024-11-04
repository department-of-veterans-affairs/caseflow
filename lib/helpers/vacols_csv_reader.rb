# frozen_string_literal: true

class VacolsCSVReader
  # :nocov:
  def initialize(klass, date_shift = nil)
    @klass = klass
    @date_shift = date_shift
    @items = []
    klass.delete_all
  end

  def call
    populate_items_from_csv

    klass.columns_hash.each do |column_name, column_object|
      if date_shift && column_object.type == :date
        dateshift_field(items, date_shift, column_name)
      elsif column_object.type == :string
        truncate_string(items, column_object.sql_type, column_name)
      end
    end

    klass.import(items)
  end

  private

  attr_reader :klass, :date_shift, :items
  attr_writer :items

  def populate_items_from_csv
    CSV.foreach(Rails.root.join("docker-bin/oracle_libs", klass.name + "_dump.csv"), headers: true) do |row|
      row_hash = row.to_h
      items << klass.new(row_hash) if klass.primary_key.nil? || !row_hash [klass.primary_key].nil?
    end
  end

  def dateshift_field(items, date_shift, column_name)
    items.map! do |item|
      item[column_name] = item[column_name] + date_shift.seconds if item[column_name]
      item
    end
  end

  def truncate_string(items, sql_type, column_name)
    max_index = /\((\d*)\)/.match(sql_type)[1].to_i - 1
    items.map! do |item|
      item[column_name] = item[column_name][0..max_index] if item[column_name]
      item
    end
  end
  # :nocov:
end
