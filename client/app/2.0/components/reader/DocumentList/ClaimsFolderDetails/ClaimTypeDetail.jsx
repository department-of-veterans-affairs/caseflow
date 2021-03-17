// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { HearingWorksheetLink } from 'components/reader/DocumentList/ClaimsFolderDetails/HearingWorksheetLink';
import { formatAppealType } from 'utils/reader';

/**
 * Hearing Worksheet Link React Component
 * @param {Object} props -- React props containing the hearings
 *
 */
export const ClaimTypeDetail = (claim) => (
  <div className="claim-detail-container">
    <span className="claim-detail-type-info">{formatAppealType(claim)}</span>
    {claim.hearings && claim.hearings.length > 0 && <HearingWorksheetLink hearings={claim.hearings} />}
  </div>
);

ClaimTypeDetail.propTypes = {
  hearings: PropTypes.array
};
