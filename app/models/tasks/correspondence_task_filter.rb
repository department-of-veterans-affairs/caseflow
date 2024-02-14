class CorrespondenceTaskFilter < TaskFilter

  def filter_by_va_dor(date_info)

    #0 between
    #1  (before this date)
    #2  (after this date)
    #3 on
    date_type = date_info.split(",")[0]
    first_date = date_info.split(",")[1]
    second_date = date_info.split(",")[2]
    case date_type
    when "0"
      tasks.joins(:appeal)
        .where(
          "correspondences.va_date_of_receipt < ? AND correspondence.va_date_of_receipt > ?",
          Time.zone.parse(first_date),
          Time.zone.parse(second_date)
        )
    when "1"
      tasks.joins(:appeal).where("correspondences.va_date_of_receipt < ?", Time.zone.parse(first_date))
    when "2"
      tasks.joins(:appeal).where("correspondences.va_date_of_receipt > ?", Time.zone.parse(first_date))
    when "3"
      # binding.pry
      tasks.joins(:appeal).where("DATE(correspondences.va_date_of_receipt) = (?)", Time.zone.parse(first_date))
    end
  end

  def filtered_tasks
    filter_params.each do |filter_param|
      value_hash = Rack::Utils.parse_nested_query(filter_param).deep_symbolize_keys
      if value_hash[:col] == "vaDor"
        @tasks = filter_by_va_dor(value_hash[:val])
      end
    end
    @tasks
  end
end
