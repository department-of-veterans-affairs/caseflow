import * as React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { css } from 'glamor';
import CorrespondenceTable from './CorrespondenceTable';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';

const rootStyles = css({
  '.usa-alert + &': {
    marginTop: '1.5em'
  }
});

// import {
//   initialAssignTasksToUser,
//   initialCamoAssignTasksToVhaProgramOffice
// } from '../QueueActions';

class CorrespondenceCases extends React.PureComponent {
  render = () => {
    const {
      organizations,
      featureToggles
    } = this.props;

    return <div className={rootStyles}>
      <h1 {...css({ display: 'inline-block' })}>{COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_CORRESPONDENCE_CASES}</h1>
      <QueueOrganizationDropdown organizations={organizations} />

      <React.Fragment>
        <div>
          <CorrespondenceTable />
        </div>
      </React.Fragment>
    </div>;
  }
}

CorrespondenceCases.propTypes = {
  organizations: PropTypes.array,
  featureToggles: PropTypes.object
};

export default CorrespondenceCases;
