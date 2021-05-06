if LogStasher.enabled?
  LogStasher.add_custom_fields_to_request_context do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    # You can log custom request fields using this block
    fields[:user] = current_user && current_user.css_id
    fields[:site] = request.path =~ /^\/api/ ? 'api' : 'user'
  end
end