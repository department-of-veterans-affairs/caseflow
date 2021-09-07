import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import {
  TEAM_MANAGEMENT_NAME_COLUMN_HEADING,
  TEAM_MANAGEMENT_PRIORITY_DISTRIBUTION_COLUMN_HEADING,
  TEAM_MANAGEMENT_REQUESTED_DISTRIBUTION_COLUMN_HEADING,
  TEAM_MANAGEMENT_URL_COLUMN_HEADING,
  TEAM_MANAGEMENT_PARTICIPANT_ID_COLUMN_HEADING
} from 'app/../COPY';
import { OrgRow } from './OrgRow';

const labelRowStyling = css({
  '& td': { fontWeight: 'bold' }
});

export const OrgList = React.memo(
  ({ isRepresentative, onUpdate, orgs, showDistributionToggles, statuses }) => {
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
            onUpdate={onUpdate}
            status={statuses?.[org.id]}
          />
        ))}
      </React.Fragment>
    );
  }
);

OrgList.defaultProps = {
  isRepresentative: false,
  showDistributionToggles: false
};

OrgList.propTypes = {
  orgs: PropTypes.array,
  isRepresentative: PropTypes.bool,
  showDistributionToggles: PropTypes.bool,
  onUpdate: PropTypes.func,
  statuses: PropTypes.shape({
    [PropTypes.string]: PropTypes.shape({
      loading: PropTypes.object,
      saved: PropTypes.object,
      error: PropTypes.object
    })
  })
};
