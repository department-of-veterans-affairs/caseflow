# frozen_string_literal: true

class MembershipRequestMailBuilderFactory
  def self.get_mail_builder(organization_type)
    case organization_type
    when "VHA"
      VhaMembershipRequestMailBuilder
    else
      fail NotImplementedError
    end
  end
end
