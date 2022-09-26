// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import IssueList from 'app/queue/components/IssueList';
import { ClaimTypeDetail } from 'components/reader/DocumentList/ClaimsFolderDetails/ClaimTypeDetail';
import { rowStyles, issueStyles } from 'styles/reader/DocumentList/ClaimsFolderDetails';

/**
 * No Appeal React Component
 * @param {Object} props -- React props containing the hearings
 *
 */
export const AppealDetails = ({ appeal }) => (
  <div>
    <div tabIndex={0} {...rowStyles}>
      <div>
        <b>Veteran ID</b><br />
        <span>{appeal.vbms_id}</span>
      </div>
      <div>
        <b>Type</b><br />
        <span>{appeal.type}</span>
        <ClaimTypeDetail appeal={appeal} />
      </div>
      <div>
        <b>Docket Number</b><br />
        <span>{appeal.docket_number}</span>
      </div>
      {appeal.regional_office && (
        <div>
          <b>Regional Office</b><br />
          <span>{`${appeal.regional_office.key} - ${appeal.regional_office.city}`}</span>
        </div>
      )}
    </div>
    <div tabIndex={0} id="claims-folder-issues" {...issueStyles}>
      <b>Issues</b><br />
      <IssueList
        issuesOnly
        appeal={{
          ...appeal,
          isLegacyAppeal: appeal.docket_name === 'legacy'
        }}
      />
    </div>
  </div>
);

AppealDetails.propTypes = {
  appeal: PropTypes.object
};
