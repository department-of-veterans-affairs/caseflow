# frozen_string_literal: true

class MembershipRequestSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  # attribute :note

  attribute :name do |object|
    object.organization.try(:name)
  end

  attribute :url do |object|
    object.organization.try(:url)
  end

  attribute :orgType do |object|
    object.organization.try(:type)
  end

  attribute :orgId do |object|
    object.organization.try(:id)
  end
end
