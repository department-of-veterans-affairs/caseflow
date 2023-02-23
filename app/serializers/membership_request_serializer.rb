# frozen_string_literal: true

class MembershipRequestSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :note
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

  attribute :userNameWithCssId do |object|
    requestor = object.requestor
    # TODO: Should this need nullsafe? Requestor shouldn't be able to be nil in the database.
    "#{requestor&.full_name} (#{requestor&.css_id})"
  end
end
