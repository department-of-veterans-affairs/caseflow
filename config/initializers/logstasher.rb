if LogStasher.enabled?
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    # You can log custom request fields using this block
    fields[:user] = RequestStore.store[:current_user]
    fields[:site] = request.path =~ /^\/api/ ? 'api' : 'user'
  end
end