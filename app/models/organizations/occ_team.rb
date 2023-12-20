# frozen_string_literal: true

##
# Office of Chief Counsel Organization
#

class OccTeam < Organization
  def self.singleton
    OccTeam.first || OccTeam.create(name: "Office of Chief Counsel", url: "occ-team")
  end
end
