# frozen_string_literal: true

class UserFinder
  def initialize(name: nil, css_id: nil, role: nil, organization: nil)
    @css_id = css_id
    @role = role
    @organization = organization
    @name = name

    fail "Must pass css_id, name, role or organization" unless css_id || name || role || organization
  end

  def users
    # filter out the empty arrays, then find the intersection
    [
      users_matching_name,
      users_matching_role,
      users_matching_css_id,
      users_matching_organization
    ].reject(&:none?).inject(&:&)
  end

  private

  attr_reader :css_id, :name, :role, :organization

  def users_matching_role
    return [] if role.blank?

    case role
    when Constants::USER_ROLE_TYPES["judge"]
      Judge.list_all
    when Constants::USER_ROLE_TYPES["attorney"]
      Attorney.list_all_excluding_judges
    when Constants::USER_ROLE_TYPES["hearing_coordinator"]
      User.list_hearing_coordinators
    when "non_judges"
      User.where.not(id: JudgeTeam.all.map(&:judge).reject(&:nil?).map(&:id))
    else
      []
    end
  end

  def users_matching_css_id
    return [] if css_id.blank?

    User.where("css_id LIKE (?)", "%#{css_id.upcase}%")
  end

  def users_matching_name
    return [] if name.blank?

    name_segments = name.split(/\W/)

    User.where(
      "full_name ILIKE (?) OR full_name ILIKE (?)",
      "%#{name_segments.join('%')}%",
      "%#{name_segments.reverse.join('%')}%"
    )
  end

  def users_matching_organization
    return [] if organization.blank?

    org = organization.is_a?(String) ? Organization.find_by_name_or_url(organization) : organization

    fail "No such Organization #{organization}" if org.blank?

    org.users
  end
end
