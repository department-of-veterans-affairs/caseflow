import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  appealsWithTasksSelector
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const noAppeals = !_.size(this.props.appeals);
    let tableContent;

    if (noAppeals) {
      tableContent = <StatusMessage title={COPY.NO_TASKS_IN_ATTORNEY_QUEUE_TITLE}>
        {COPY.NO_TASKS_IN_ATTORNEY_QUEUE_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
        <TaskTable
          includeDetailsLink
          includeType
          includeDocketNumber
          includeIssueCount
          includeDaysWaiting
          includeReaderLink
          appeals={this.props.appeals}
        />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  appeals: PropTypes.array.isRequired
};

const mapStateToProps = (state) => {
  return ({
    appeals: appealsWithTasksSelector(state)
  });
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
