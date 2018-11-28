import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import QueueSelectorDropdown from './components/QueueSelectorDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  tasksByOrganization
} from './selectors';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

const containerStyles = css({
  position: 'relative'
});

class OrganizationQueue extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
        page: <TaskTableTab
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.unassignedTasks}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
        page: <TaskTableTab
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.assignedTasks}
        />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableTab
          description={
            sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.completedTasks}
        />
      }
    ];

    return <AppSegment filledBackground styling={containerStyles}>
      <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
        <QueueSelectorDropdown organizations={this.props.organizations} />
        <TabWindow
          name="tasks-organization-queue"
          tabs={tabs}
        />
      </div>
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  tasks: PropTypes.array.isRequired
};

const mapStateToProps = (state) => ({
  organizations: state.ui.organizations,
  unassignedTasks: getUnassignedOrganizationalTasks(state),
  assignedTasks: getAssignedOrganizationalTasks(state),
  completedTasks: getCompletedOrganizationalTasks(state),
  tasks: tasksByOrganization(state)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p>{description}</p>
  <TaskTable
    includeDetailsLink
    includeTask
    includeType
    includeDocketNumber
    includeDaysWaiting
    includeReaderLink
    tasks={tasks}
  />
</React.Fragment>;
