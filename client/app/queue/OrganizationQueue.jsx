import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  trackingTasksForOrganization
} from './selectors';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';
import Alert from '../components/Alert';

const containerStyles = css({
  position: 'relative'
});

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const { success } = this.props;
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
        page: <UnassignedTaskTableTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.unassignedTasks}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
        page: <TaskTableWithUserColumnTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.assignedTasks}
        />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableWithUserColumnTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.completedTasks}
        />
      }
    ];

    // Focus on the first tab in the list of tabs unless we have an "all cases" view, in which case the first tab will
    // be the "all cases" tab. In that case focus on the second tab which will be the first tab with workable tasks.
    let focusedTab = 0;

    if (this.props.organizationIsVso) {
      focusedTab = 1;
      tabs.unshift({
        label: COPY.ALL_CASES_QUEUE_TABLE_TAB_TITLE,
        page: <React.Fragment>
          <p className="cf-margin-top-0">
            {sprintf(COPY.ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, this.props.organizationName)}
          </p>
          <TaskTable
            includeDetailsLink
            includeIssueCount
            includeType
            includeDocketNumber
            tasks={this.props.trackingTasks}
          />
        </React.Fragment>
      });
    }

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
        <QueueOrganizationDropdown organizations={this.props.organizations} />
        <TabWindow
          name="tasks-organization-queue"
          tabs={tabs}
          defaultPage={focusedTab}
        />
      </div>
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    organizationName: state.ui.activeOrganization.name,
    organizationIsVso: state.ui.activeOrganization.isVso,
    organizations: state.ui.organizations,
    unassignedTasks: getUnassignedOrganizationalTasks(state),
    assignedTasks: getAssignedOrganizationalTasks(state),
    completedTasks: getCompletedOrganizationalTasks(state),
    trackingTasks: trackingTasksForOrganization(state)
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);

const UnassignedTaskTableTab = ({ description, tasks, organizationName }) => <React.Fragment>
  <p className="cf-margin-top-0">{description}</p>
  <TaskTable
    includeHearingBadge
    includeDetailsLink
    includeTask
    includeRegionalOffice={organizationName === 'Hearing Management'}
    includeType
    includeDocketNumber
    includeDaysWaiting
    includeReaderLink
    includeNewDocsIcon
    tasks={tasks}
  />
</React.Fragment>;

const TaskTableWithUserColumnTab = ({ description, tasks, organizationName }) => <React.Fragment>
  <p className="cf-margin-top-0">{description}</p>
  <TaskTable
    includeHearingBadge
    includeDetailsLink
    includeTask
    includeRegionalOffice={organizationName === 'Hearing Management'}
    includeType
    includeAssignedTo
    includeDocketNumber
    includeDaysWaiting
    tasks={tasks}
  />
</React.Fragment>;
