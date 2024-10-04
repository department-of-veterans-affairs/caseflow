### ###
### merge our maintained mappings with the existing mappings in TimeZone
### Doesn't provide all timezones we need
### Add timezones to here for more timezone support
### ###
TIMEZONE_MAPPINGS = {
  "Philippine Standard Time" => "Asia/Manila",
  "Mountain Time (US & Canada)" => "America/Boise",
  "Eastern Time (US & Canada)" => "America/Kentucky/Louisville"
}
ActiveSupport::TimeZone.const_set(:MAPPING, ActiveSupport::TimeZone::MAPPING.merge(TIMEZONE_MAPPINGS))
