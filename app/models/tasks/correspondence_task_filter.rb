# frozen_string_literal: true

class CorrespondenceTaskFilter < TaskFilter
  def filter_by_va_dor(date_info)
    date_type, first_date, second_date = date_info.split(",")

    case date_type
    when "0"
      filter_between_dates(first_date, second_date)
    when "1"
      filter_before_date(first_date)
    when "2"
      filter_after_date(first_date)
    when "3"
      filter_on_date(first_date)
    end
  end

  def filter_by_date(date_info)
    date_type, first_date, second_date = date_info.split(",")

    case date_type
    when "0"
      tasks.where("closed_at > ? AND closed_at < ?", Time.zone.parse(first_date), Time.zone.parse(second_date))
    when "1"
      tasks.where("closed_at < ?", Time.zone.parse(first_date))
    when "2"
      tasks.where("closed_at > ?", Time.zone.parse(first_date))
    when "3"
      tasks.where("DATE(closed_at) = (?)", Time.zone.parse(first_date))
    end
  end

  def filter_by_task(task_type)
    tasks.where("type = (?)", task_type)
  end

  def filtered_tasks
    va_dor_params = filter_params.select { |param| param.include?("col=vaDor") }
    task_column_params = filter_params.select { |param| param.include?("col=taskColumn") }
    result = tasks.all # Assuming Task is the name of your ActiveRecord model
    va_dor_params.each do |param|
      value_hash = Rack::Utils.parse_nested_query(param).deep_symbolize_keys
      result = result.merge(filter_by_va_dor(value_hash[:val]))
    end

    task_column_params.each do |param|
      value_hash = Rack::Utils.parse_nested_query(param).deep_symbolize_keys
      result = result.merge(filter_by_task(value_hash[:val]))
    end

    result
  end

  private

  def filter_between_dates(start_date, end_date)
    tasks.joins(:appeal)
      .where("correspondences.va_date_of_receipt > ? AND correspondences.va_date_of_receipt < ?",
             Time.zone.parse(start_date),
             Time.zone.parse(end_date))
  end

  def filter_before_date(date)
    tasks.joins(:appeal).where("correspondences.va_date_of_receipt < ?", Time.zone.parse(date))
  end

  def filter_after_date(date)
    tasks.joins(:appeal).where("correspondences.va_date_of_receipt > ?", Time.zone.parse(date))
  end

  def filter_on_date(date)
    tasks.joins(:appeal).where("DATE(correspondences.va_date_of_receipt) = (?)", Time.zone.parse(date))
  end
end
