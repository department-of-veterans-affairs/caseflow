# frozen_string_literal: true

class CorrespondenceTaskFilter < TaskFilter
  def filter_by_va_dor(date_info)
    date_type = date_info.split(",")[0]
    first_date = date_info.split(",")[1]
    second_date = date_info.split(",")[2]
    # case map
    # 0 between these dates
    # 1 before this date
    # 2 after this date
    # 3 on this date
    case date_type
    when "0"
      tasks.joins(:appeal)
        .where(
          "correspondences.va_date_of_receipt > ? AND correspondences.va_date_of_receipt < ?",
          Time.zone.parse(first_date),
          Time.zone.parse(second_date)
        )
    when "1"
      tasks.joins(:appeal).where("correspondences.va_date_of_receipt < ?", Time.zone.parse(first_date))
    when "2"
      tasks.joins(:appeal).where("correspondences.va_date_of_receipt > ?", Time.zone.parse(first_date))
    when "3"
      tasks.joins(:appeal).where("DATE(correspondences.va_date_of_receipt) = (?)", Time.zone.parse(first_date))
    end
  end

  def filter_by_date(date_info)
   date_type = date_info.split(",")[0]
   first_date = date_info.split(",")[1]
   second_date = date_info.split(",")[2]
   case date_type
   when "0"
     tasks
     .where(
         "closed_at > ? AND closed_at < ?",
         Time.zone.parse(first_date),
         Time.zone.parse(second_date)
       )
   when "1"
     tasks.where("closed_at < ?", Time.zone.parse(first_date))
   when "2"
     tasks.where("closed_at > ?", Time.zone.parse(first_date))
   when "3"
     tasks.where("DATE(closed_at) = (?)", Time.zone.parse(first_date))
   end
  end

  def filtered_tasks
    filter_params.each do |filter_param|
      value_hash = Rack::Utils.parse_nested_query(filter_param).deep_symbolize_keys
      if value_hash[:col] == "vaDor"
        @tasks = filter_by_va_dor(value_hash[:val])
      elsif value_hash[:col] == "completedDateColumn"
        @tasks = filter_by_date(value_hash[:val])
      end
    end
    @tasks
  end
end
