import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { css } from 'glamor';
import ListCorrespondenceTable from './corrrespondenceList';
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

class CorrespondenceCasesList extends React.PureComponent {
  // componentDidMount = () => {
  //   this.props.resetSuccessMessages();
  //   this.props.resetErrorMessages();
  // }
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
          <React.Fragment>
            <ListCorrespondenceTable />
          </React.Fragment>
        </div>
      </React.Fragment>
    </div>;
  }
}

CorrespondenceCasesList.propTypes = {
  organizations: PropTypes.array,
  featureToggles: PropTypes.object
};

export default CorrespondenceCasesList;
