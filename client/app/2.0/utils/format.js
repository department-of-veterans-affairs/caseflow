/**
 * Helper Method to format the Appeal type based on claim info
 * @param {Object} claim -- The claim to determine the appeal info
 * @returns {string} -- The formatted appeal type
 */
export const formatAppealType = (claim) => {
  // Handle the Claim Type
  if (claim.cavc && claim.aod) {
    return 'AOD, CAVC';
  } else if (claim.cavc) {
    return 'CAVC';
  } else if (claim.aod) {
    return 'AOD';
  }

  // Default to return nothing
  return '';
};
