class ApplicationJob < ActiveJob::Base
  include ApplicationAttributes
  application_attr :intake
end
