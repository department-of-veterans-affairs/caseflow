// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import TabWindow from '../components/TabWindow';
import COPY from '../../COPY.json';

import type { TaskWithAppeal } from './types/models';
import type { State } from './types/state';

type Params = {|
|};

type Props = Params & {|
  // Action creators
  clearCaseSelectSearch: typeof clearCaseSelectSearch
|};

class ColocatedTaskListView extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  render = () => {
    const tabs = [{
      label: 'New',
      page: <NewTasksTab />
    }, {
      label: 'On hold',
      page: <OnHoldTasksTab />
    }];

    return <AppSegment filledBackground>
      <TabWindow name="tasks-tabwindow" tabs={tabs} />
    </AppSegment>;
  };
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch
}, dispatch);

export default (connect(null, mapDispatchToProps)(ColocatedTaskListView): React.ComponentType<Params>);

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

const OnHoldTasksTab = connect(
  (state: State) => ({ tasks: amaTasksOnHoldByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<AmaTask> }) => {
    return <div>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
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
