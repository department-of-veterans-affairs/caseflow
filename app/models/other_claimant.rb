# frozen_string_literal: true

##
# OtherClaimant is used when none of Veteran, Dependent, or Attorney claimant is applicable, largely
# due to not having a canonical BGS source for the claimant's participant ID.
# Currently used for attorney fee cases when the attorney isn't found in the BGS attorney database.

class OtherClaimant < Claimant
end
