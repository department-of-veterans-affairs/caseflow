# frozen_string_literal: true

class SpecialIssueEditTeam < Organization
  alias_attribute :full_name, :name

  def self.singleton
    SpecialIssueEditTeam.first || SpecialIssueEditTeam.create(
      name: "Special Issue Edit Team",
      url: "special-issue-edit-team"
    )
  end
end
