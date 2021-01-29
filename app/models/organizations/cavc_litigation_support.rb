# frozen_string_literal: true

##
# Team that handles CAVC-related tasks.
# For Litigation Support team members who only work on CAVC cases.

class CavcLitigationSupport < Organization
  def self.singleton
    CavcLitigationSupport.first ||
      CavcLitigationSupport.create(name: "CAVC Litigation Support", url: "cavc-lit-support")
  end
end
