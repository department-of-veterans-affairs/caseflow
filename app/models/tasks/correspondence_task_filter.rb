# frozen_string_literal: true

class CorrespondenceTaskFilter < TaskFilter
  def filtered_tasks
    result = tasks.all

    filter_params.each do |param|
      case param
      when /col=vaDor/
        value_hash = Rack::Utils.parse_nested_query(param).deep_symbolize_keys
        result = result.merge(filter_by_va_dor(value_hash[:val]))
      when /col=packageDocTypeColumn/
        value_hash = Rack::Utils.parse_nested_query(param).deep_symbolize_keys
        result = result.merge(filter_by_nod(value_hash[:val]))
      when /col=taskColumn/
        task_column_params = param.sub("col=taskColumn&val=", "").split("|")
        result = result.merge(filter_by_task(task_column_params))
      when /col=correspondenceCompletedDateColumn/
        value_hash = Rack::Utils.parse_nested_query(param).deep_symbolize_keys
        result = result.merge(filter_by_date_completed(value_hash[:val]))
      end
    end

    result
  end

  private

  def filter_by_nod(nod_value)
    # If both NOD and Non-NOD checkboxes are selected in the filter dropdown,
    # nod_value will be "true|false" or "false|true",
    # so we return all the tasks if the string contains pipe character.
    return tasks if nod_value.include?("|")

    tasks.joins(:appeal).where("correspondences.nod = ?", nod_value)
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

  def filter_by_date_completed(date_info)
    date_type, first_date, second_date = date_info.split(",")

    case date_type
    when "0"
      date_completed_filter_between_dates(first_date, second_date)
    when "1"
      date_completed_filter_before_date(first_date)
    when "2"
      date_completed_filter_after_date(first_date)
    when "3"
      date_completed_filter_on_date(first_date)
    end
  end

  def filter_by_task(task_types)
    # used to store the results of each task query
    collection = nil
    task_types.each do |task_type|
      task_type_match = tasks.where(type: task_type)
      collection = collection.nil? ? tasks.merge(task_type_match) : collection.or(tasks.merge(task_type_match))
    end
    collection
  end

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

  def date_completed_filter_between_dates(start_date, end_date)
    tasks.where("closed_at > ? AND closed_at < ?",
                Time.zone.parse(start_date),
                Time.zone.parse(end_date))
  end

  def date_completed_filter_before_date(date)
    tasks.where("closed_at < ?", Time.zone.parse(date))
  end

  def date_completed_filter_after_date(date)
    tasks.where("closed_at > ?", Time.zone.parse(date))
  end

  def date_completed_filter_on_date(date)
    tasks.where("DATE(closed_at) = (?)", Time.zone.parse(date))
  end
end
