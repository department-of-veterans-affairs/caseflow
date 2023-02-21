# frozen_string_literal: true

class MembershipRequestMailerFactory
  def self.get_mailer(type)
    case type
    when "VHA"
      VhaMembershipRequestMailer
    else
      MembershipRequestMailer
    end
  end
end
