# frozen_string_literal: true

class JudgeTeamRole < ApplicationRecord
  belongs_to :organizations_user, class_name: "::OrganizationsUser"

  has_one :user, through: :organizations_user
  has_one :organization, through: :organizations_user

  validates :organizations_user, presence: true

  class << self
    def users
      all.map { |role| role.organizations_user.user }
    end
  end
end
