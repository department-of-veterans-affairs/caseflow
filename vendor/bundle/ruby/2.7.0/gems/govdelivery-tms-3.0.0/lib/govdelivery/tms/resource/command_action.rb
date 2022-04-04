module GovDelivery::TMS #:nodoc:
  # CommandAction object represent the results of Commands for a particular input (e.g. an incoming SMS message)
  #
  # This resource is read-only.
  #
  # ==== Attributes
  #
  # * +http_response_code+ - e.g. 200, 404, etc.
  # * +http_content_type+ - text/html, etc.
  # * +http_body+ - Request body (if it's <500 characters, otherwise it'll be nil)
  #
  class CommandAction
    include InstanceResource

    readonly_attributes :status, :content_type, :response_body, :created_at
  end
end
