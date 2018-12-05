import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import Button from '../components/Button';
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

class NonCompOrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const tabs = [
      {
        label: sprintf(
          'In progress (%s)', this.props.unassignedTasks.length),
        page: <TaskTableTab
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.unassignedTasks}
        />
      },
      {
        label: sprintf(
          'Completed (%s)', this.props.completedTasks.length),
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
        <h1 {...fullWidth}>{this.props.organizationName}</h1>
        <h2>Reviews needing action</h2>
        <span className="cf-push-right">
          <Button type="button"
            name="IntakeNewForm"
            onClick={null}>
            + Intake New Form
          </Button>
        </span>
        <p>Review each issue and select a disposition.</p>
        <TabWindow
          name="tasks-organization-queue"
          tabs={tabs}
        />
      </div>
    </AppSegment>;
  };
}

NonCompOrganizationQueue.propTypes = {
  tasks: PropTypes.array.isRequired
};

const mapStateToProps = (state) => ({
  organizations: state.ui.organizations,
  unassignedTasks: getUnassignedOrganizationalTasks(state),
  completedTasks: getCompletedOrganizationalTasks(state),
  tasks: tasksByOrganization(state)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(NonCompOrganizationQueue);

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p className="cf-margin-top-0">{description}</p>
  <TaskTable
    includeClaimantLink
    includeClaimantSsn
    includeTask
    includeIssueCount
    includeDaysWaiting
    tasks={tasks}
  />
</React.Fragment>;
