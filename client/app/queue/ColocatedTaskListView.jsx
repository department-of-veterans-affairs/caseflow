// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

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

const styles = {
  container: css({
    position: 'relative'
  }),
  dropdownTrigger: css({
    marginRight: 0
  }),
  dropdownButton: css({
    position: 'absolute',
    top: '40px',
    right: '40px'
  }),
  dropdownList: css({
    top: '3.55rem',
    right: '0',
    width: '26rem'
  })
};

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
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

  render = () => {
    let dropdown;
    const {
      success,
      organizations,
      numNewTasks,
      numPendingTasks,
      numOnHoldTasks
    } = this.props;

    // debugge;

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

    const dropdownButtonList = (orgs) => {
      return <ul className="cf-dropdown-menu active" {...styles.dropdownList}>
        <li key={0}>
          <Link className="usa-button-secondary usa-button"
            href="#FIXME">
            {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL}
          </Link>
        </li>

        {orgs.map((org, index) =>
          <li key={index + 1}>
            <Link className="usa-button-secondary usa-button"
              href={org.target}>
              {sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name)}
            </Link>
          </li>)}
      </ul>;
    };

    if (organizations.length > 0) {
      dropdown = <div className="cf-dropdown" {...styles.dropdownButton}>
        <a onClick={this.onMenuClick}
          className="cf-dropdown-trigger usa-button usa-button-secondary"
          {...styles.dropdownTrigger}>
          {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
        </a>
        {this.state.menu && dropdownButtonList(organizations) }
      </div>;
    }

    return <AppSegment filledBackground styling={styles.container}>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={marginBottom(1)} />}
      <h1 {...fullWidth}>{COPY.COLOCATED_QUEUE_PAGE_TABLE_TITLE}</h1>

      {dropdown}

      <TabWindow name="tasks-tabwindow" tabs={tabs} />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    organizationIds: state.ui.organizationIds,
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

const CompleteTasksTab = connect(
  (state: State) => ({ tasks: completeTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeCompletedDate
        includeCompletedToName
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });
