### ###
### merge our maintained mappings with the existing mappings in TimeZone
### Doesn't provide all timezones we need
### Add timezones to here for more timezone support
### ###
TIMEZONE_MAPPINGS = {
  "Philippine Standard Time" => "Asia/Manila"
}
ActiveSupport::TimeZone.const_set(:MAPPING, ActiveSupport::TimeZone::MAPPING.merge(TIMEZONE_MAPPINGS))
