class VACOLS::Record < ActiveRecord::Base
  self.abstract_class = true

  if FeatureToggle.enabled?(:vacols_forward_proxy)
    establish_connection "#{Rails.env}_vacols_proxy".to_sym
  else
    establish_connection "#{Rails.env}_vacols".to_sym
  end


  ActiveSupport.run_load_hooks(:active_record_vacols, VACOLS::Record)

  # This method calculates the appropriate date & timezone
  # necessary to get a relative date within vacols
  # `date_diff` will most commonly be the rails date helpers
  # example: relative_vacols_date(7.days)
  def self.relative_vacols_date(date_diff)
    rounded_current_time - date_diff
  end

  def self.rounded_current_time
    Time.zone = "Eastern Time (US & Canada)"
    current_time = Time.zone.now

    # Round off hours, minutes, and seconds
    Time.zone.local(
      current_time.year,
      current_time.month,
      current_time.day
    )
  end
end
