class JudgeTeamRole < ApplicationRecord
  belongs_to :organizations_user, class_name: ::OrganizationsUser.name

  has_one :user, through: :organizations_user
  has_one :organization, through: :organizations_user
end
