# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.0 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.0`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# Cookie serializer: 2 options
#
# If you're upgrading and haven't set `cookies_serializer` previously, your cookie serializer
# is `:marshal`. The default for new apps is `:json`.
#
# Rails.application.config.action_dispatch.cookies_serializer = :json
#
#
# To migrate an existing application to the `:json` serializer, use the `:hybrid` option.
#
# Rails transparently deserializes existing (Marshal-serialized) cookies on read and
# re-writes them in the JSON format.
#
# It is fine to use `:hybrid` long term; you should do that until you're confident *all* your cookies
# have been converted to JSON. To keep using `:hybrid` long term, move this config to its own
# initializer or to `config/application.rb`.
#
# Rails.application.config.action_dispatch.cookies_serializer = :hybrid
#
#
# If your cookies can't yet be serialized to JSON, keep using `:marshal` for backward-compatibility.
#
# If you have configured the serializer elsewhere, you can remove this section of the file.
#
# See https://guides.rubyonrails.org/action_controller_overview.html#cookies for more information.

# Change the return value of `ActionDispatch::Request#content_type` to the Content-Type header without modification.
# Rails.application.config.action_dispatch.return_only_request_media_type_on_content_type = false

# Active Storage `has_many_attached` relationships will default to replacing the current collection instead of appending to it.
# Thus, to support submitting an empty collection, the `file_field` helper will render an hidden field `include_hidden` by default when `multiple_file_field_include_hidden` is set to `true`.
# See https://guides.rubyonrails.org/configuring.html#config-active-storage-multiple-file-field-include-hidden for more information.
# Rails.application.config.active_storage.multiple_file_field_include_hidden = true

# ** Please read carefully, this must be configured in config/application.rb (NOT this file) **
# Disables the deprecated #to_s override in some Ruby core classes
# See https://guides.rubyonrails.org/configuring.html#config-active-support-disable-to-s-conversion for more information.
# config.active_support.disable_to_s_conversion = true
