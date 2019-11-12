# frozen_string_literal: true

class JudgeTeamRole < ApplicationRecord
  belongs_to :organizations_user, class_name: "::OrganizationsUser"

  has_one :user, through: :organizations_user
  has_one :organization, through: :organizations_user

  validates :organizations_user, presence: true
end
