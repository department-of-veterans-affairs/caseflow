// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector,
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
    const { success } = this.props;
    const tabs = [
      {
        label: COPY.COLOCATED_QUEUE_PAGE_NEW_TAB_TITLE,
        page: <NewTasksTab />
      },
      {
        label: COPY.COLOCATED_QUEUE_PAGE_PENDING_TAB_TITLE,
        page: <PendingTasksTab />
      },
      {
        label: COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TAB_TITLE,
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
    success
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
    return <div>
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
    </div>;
  });

const PendingTasksTab = connect(
  (state: State) => ({ tasks: onHoldTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <div>
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
    </div>;
  });

const OnHoldTasksTab = connect(
  (state: State) => ({ tasks: onHoldTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <div>
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
    </div>;
  });
