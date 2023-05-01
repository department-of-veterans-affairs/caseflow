# frozen_string_literal: true

class MembershipRequestMailBuilderFactory
  def self.get_mail_builder(organization_type)
    builder_hash = Hash.new(NotImplementedError).merge(
      VHA: VhaMembershipRequestMailBuilder
    )

    builder_hash[organization_type.to_sym]
  end
end
