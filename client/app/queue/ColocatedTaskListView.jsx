// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector,
  pendingTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector
} from './selectors';
import { hideSuccessMessage } from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import COPY from '../../COPY.json';

import Alert from '../components/Alert';
import TabWindow from '../components/TabWindow';

import type { TaskWithAppeal } from './types/models';
import type { State, UiStateMessage } from './types/state';

type Params = {||};

type Props = Params & {|
  // store
  success: UiStateMessage,
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
      numNewTasks,
      numPendingTasks,
      numOnHoldTasks
    } = this.props;
    const tabs = [
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_NEW_TAB_TITLE, { numNewTasks }),
        page: <NewTasksTab />
      },
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_PENDING_TAB_TITLE, { numPendingTasks }),
        page: <PendingTasksTab />
      },
      {
        label: sprintf(COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TAB_TITLE, { numOnHoldTasks }),
        page: <OnHoldTasksTab />
      }
    ];

    return <AppSegment filledBackground>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      <TabWindow name="tasks-tabwindow" tabs={tabs} />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
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
  (state: State) => ({ tasks: newTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_NEW_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const PendingTasksTab = connect(
  (state: State) => ({ tasks: pendingTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_PENDING_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const OnHoldTasksTab = connect(
  (state: State) => ({ tasks: onHoldTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });
