class GovDelivery::TMS::Emails
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::SmsMessages
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::EmailMessages
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::Recipients
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::EmailRecipients
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::EmailRecipientOpens
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::EmailRecipientClicks
  include GovDelivery::TMS::CollectionResource
end

# A collection of Keyword objects.
#
# @example
#    keywords = client.keywords.get
#
class GovDelivery::TMS::Keywords
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::InboundSmsMessages
  include GovDelivery::TMS::CollectionResource
end

# A collection of CommandType instances.
# This resource changes infrequently.  It may be used to dynamically construct a
# user interface for configuring arbitrary SMS keywords for an account.
#
# This resource is read-only.
#
# @example
#    client.command_types.get
#    client.command_types.collection.each {|at| ... }
class GovDelivery::TMS::CommandTypes
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::Commands
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::CommandActions
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::Webhooks
  include GovDelivery::TMS::CollectionResource
end

# A collection of Email Template objects.
#
# @example
#    email_template = client.email_templates.get
#
class GovDelivery::TMS::EmailTemplates
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::MessageTypes
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::SmsTemplates
  include GovDelivery::TMS::CollectionResource
end

class GovDelivery::TMS::FromAddresses
  include GovDelivery::TMS::CollectionResource
end
