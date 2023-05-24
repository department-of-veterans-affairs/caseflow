# frozen_string_literal: true

class MembershipRequestSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :note
  attribute :status
  attribute :requestedDate, &:created_at

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

  attribute :orgName do |object|
    object.organization.try(:name)
  end

  attribute :userName do |object|
    object.requestor.try(:full_name)
  end

  attribute :userNameWithCssId do |object|
    "#{object.requestor.full_name} (#{object.requestor.css_id})"
  end

  attribute :userId do |object|
    object.requestor&.id
  end
end
