# frozen_string_literal: true

##
# Office of Assessment and Improvement Organization
#

class OaiTeam < Organization
  def self.singleton
    OaiTeam.first || OaiTeam.create(name: "Office of Assessment and Improvement", url: "oai-team")
  end
end
