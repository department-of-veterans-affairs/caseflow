// @flow
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
  pendingTasksByAssigneeCssIdSelector,
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

import type { TaskWithAppeal } from './types/models';
import type { State, UiStateMessage } from './types/state';

type Params = {||};

const containerStyles = css({
  position: 'relative'
});

type Props = Params & {|
  // store
  success: UiStateMessage,
  organizations: Array<Object>,
  numNewTasks: number,
  numPendingTasks: number,
  numOnHoldTasks: number,
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch,
  hideSuccessMessage: typeof hideSuccessMessage
|};

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

  render = () => {
    const {
      success,
      organizations,
      numNewTasks,
      numPendingTasks,
      numOnHoldTasks
    } = this.props;

    const tabs = [
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_NEW_TAB_TITLE, numNewTasks),
        page: <NewTasksTab />
      },
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_PENDING_TAB_TITLE, numPendingTasks),
        page: <PendingTasksTab />
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
    numPendingTasks: pendingTasksByAssigneeCssIdSelector(state).length,
    numOnHoldTasks: onHoldTasksByAssigneeCssIdSelector(state).length
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch,
  hideSuccessMessage
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView): React.ComponentType<Params>);

const NewTasksTab = connect(
  (state: State) => ({
    tasks: newTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearing Management')
  }))(
  (props: { tasks: Array<TaskWithAppeal>, belongsToHearingSchedule: boolean }) => {
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

const PendingTasksTab = connect(
  (state: State) => ({
    tasks: pendingTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearing Management')
  }))(
  (props: { tasks: Array<TaskWithAppeal>, belongsToHearingSchedule: boolean }) => {
    return <React.Fragment>
      <p className="cf-margin-top-0">{COPY.COLOCATED_QUEUE_PAGE_PENDING_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeHearingBadge
        includeDetailsLink
        includeTask
        includeRegionalOffice={props.belongsToHearingSchedule}
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const OnHoldTasksTab = connect(
  (state: State) => ({
    tasks: onHoldTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearing Management')
  }))(
  (props: { tasks: Array<TaskWithAppeal>, belongsToHearingSchedule: boolean }) => {
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
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompleteTasksTab = connect(
  (state: State) => ({
    tasks: completeTasksByAssigneeCssIdSelector(state),
    belongsToHearingSchedule: state.ui.organizations.find((org) => org.name === 'Hearing Management')
  }))(
  (props: { tasks: Array<TaskWithAppeal>, belongsToHearingSchedule: boolean }) => {
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
