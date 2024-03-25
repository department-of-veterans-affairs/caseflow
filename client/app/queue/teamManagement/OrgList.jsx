import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import {
  TEAM_MANAGEMENT_NAME_COLUMN_HEADING,
  TEAM_MANAGEMENT_PRIORITY_DISTRIBUTION_COLUMN_HEADING,
  TEAM_MANAGEMENT_REQUESTED_DISTRIBUTION_COLUMN_HEADING,
  TEAM_MANAGEMENT_EXCLUDE_FROM_AFFINITY_CASES_COLUMN_HEADING,
  TEAM_MANAGEMENT_URL_COLUMN_HEADING,
  TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING
} from 'app/../COPY';
import { OrgRow } from './OrgRow';

const labelRowStyling = css({
  '& td': { fontWeight: 'bold' }
});

export const OrgList = React.memo(
  ({ isRepresentative, onUpdate, orgs, showDistributionToggles, showExcludeFromAffinityToggles, statuses }) => {
    return (
      <React.Fragment>
        <tr {...labelRowStyling}>
          <td>{TEAM_MANAGEMENT_NAME_COLUMN_HEADING}</td>
          {showDistributionToggles && (
            <>
              <td>{TEAM_MANAGEMENT_PRIORITY_DISTRIBUTION_COLUMN_HEADING}</td>
              <td>{TEAM_MANAGEMENT_REQUESTED_DISTRIBUTION_COLUMN_HEADING}</td>
            </>
          )}
          {showExcludeFromAffinityToggles && (
            <>
              <td colSpan={2}>{TEAM_MANAGEMENT_EXCLUDE_FROM_AFFINITY_CASES_COLUMN_HEADING}</td>
            </>
          )}
          {isRepresentative && <td>{TEAM_MANAGEMENT_URL_COLUMN_HEADING}</td>}
          {isRepresentative && <td>{TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING}</td>}
          <td />
          <td />
        </tr>
        {orgs.map((org) => (
          <OrgRow
            {...org}
            key={org.id}
            isRepresentative={isRepresentative}
            showDistributionToggles={showDistributionToggles}
            showExcludeFromAffinityToggles={showExcludeFromAffinityToggles}
            onUpdate={onUpdate}
            status={statuses?.[org.id]}
          />
        ))}

        {showExcludeFromAffinityToggles && (
          <tr {...labelRowStyling}>
            <td colSpan={7}>
            *When the box is checked, the judge will  not receive appeals with
             which there is an existing affinity relationship. Any appeal with an affinity
             relationship to that judge will immediately be released for distribution to any
             judge once the appeal is ready to distribute. Appeals that are tied
             (e.g., legacy hearing) are unaffected by this value.
            </td>
          </tr>
        )}
      </React.Fragment>
    );
  }
);

OrgList.defaultProps = {
  isRepresentative: false,
  showDistributionToggles: false,
  showExcludeFromAffinityToggles: false
};

OrgList.propTypes = {
  orgs: PropTypes.array,
  isRepresentative: PropTypes.bool,
  showDistributionToggles: PropTypes.bool,
  showExcludeFromAffinityToggles: PropTypes.bool,
  onUpdate: PropTypes.func,
  statuses: PropTypes.shape({
    [PropTypes.string]: PropTypes.shape({
      loading: PropTypes.object,
      saved: PropTypes.object,
      error: PropTypes.object
    })
  })
};
