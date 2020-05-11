import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';
import Alert from '../components/Alert';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

const containerStyles = css({
  position: 'relative'
});

const alertStyling = css({
  marginBottom: '1.5em'
});

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const { success, tasksAssignedByBulk } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      {tasksAssignedByBulk.assignedUser &&
        <Alert
          message="Please go to your individual queue to see your self assigned tasks"
          title={`You have bulk assigned
            ${tasksAssignedByBulk.numberOfTasks}
            ${tasksAssignedByBulk.taskType.replace(/([a-z])([A-Z])/g, '$1 $2')}
            tasks`}
          type="success"
          styling={alertStyling} />
      }
      <QueueTableBuilder paginationOptions={this.props.paginationOptions} />
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  clearCaseSelectSearch: PropTypes.func,
  onHoldTasks: PropTypes.array,
  organizations: PropTypes.array,
  config: PropTypes.object,
  success: PropTypes.object,
  tasksAssignedByBulk: PropTypes.object,
  paginationOptions: PropTypes.object
};

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    organizations: state.ui.organizations,
    tasksAssignedByBulk: state.queue.tasksAssignedByBulk,
    config: state.queue.queueConfig
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
