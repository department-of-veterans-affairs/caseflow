import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TaskTable from './components/TaskTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector,
  completeTasksByAssigneeCssIdSelector
} from './selectors';
import { hideSuccessMessage } from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import COPY from '../../COPY.json';
import {
  fullWidth,
  marginBottom
} from './constants';

import Alert from '../components/Alert';
import TabWindow from '../components/TabWindow';

const containerStyles = css({
  position: 'relative'
});

class ColocatedTaskListView extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

  render = () => {
    const {
      success,
      organizations,
      numNewTasks,
      numOnHoldTasks
    } = this.props;

    const tabs = [
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_NEW_TAB_TITLE, numNewTasks),
        page: <NewTasksTab />
      },
      {
        label: sprintf(COPY.QUEUE_PAGE_ON_HOLD_TAB_TITLE, numOnHoldTasks),
        page: <OnHoldTasksTab />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <CompleteTasksTab />
      }
    ];

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={marginBottom(1)} />}
      <h1 {...fullWidth}>{COPY.COLOCATED_QUEUE_PAGE_TABLE_TITLE}</h1>
      <QueueOrganizationDropdown organizations={organizations} />
      <TabWindow name="tasks-tabwindow" tabs={tabs} />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    organizations: state.ui.organizations,
    numNewTasks: newTasksByAssigneeCssIdSelector(state).length,
    numOnHoldTasks: onHoldTasksByAssigneeCssIdSelector(state).length
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch,
  hideSuccessMessage
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView));

const NewTasksTab = connect(
  (state) => ({
    tasks: newTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearings Management')
  }))(
  (props) => {
    return <React.Fragment>
      <p className="cf-margin-top-0">{COPY.COLOCATED_QUEUE_PAGE_NEW_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeHearingBadge
        includeDetailsLink
        includeTask
        includeRegionalOffice={props.belongsToHearingSchedule}
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const OnHoldTasksTab = connect(
  (state) => ({
    tasks: onHoldTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearings Management')
  }))(
  (props) => {
    return <React.Fragment>
      <p className="cf-margin-top-0">{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeHearingBadge
        includeDetailsLink
        includeTask
        includeRegionalOffice={props.belongsToHearingSchedule}
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        includeNewDocsIcon
        useOnHoldDate
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompleteTasksTab = connect(
  (state) => ({
    tasks: completeTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearings Management')
  }))(
  (props) => {
    return <React.Fragment>
      <p className="cf-margin-top-0">{COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeHearingBadge
        includeDetailsLink
        includeTask
        includeRegionalOffice={props.belongsToHearingSchedule}
        includeType
        includeDocketNumber
        includeCompletedDate
        includeCompletedToName
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });
