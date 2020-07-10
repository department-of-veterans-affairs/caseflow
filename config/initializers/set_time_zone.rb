# in process of fixing system time zone issues.
# setting to :uat only for now.

Time.zone = Rails.configuration.time_zone = "America/New_York" if Rails.current_env == :uat
