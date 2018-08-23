// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import COPY from '../../../COPY.json';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES.json';
import DECASS_WORK_PRODUCT_TYPES from '../../../constants/DECASS_WORK_PRODUCT_TYPES.json';

import SearchableDropdown from '../../components/SearchableDropdown';
import {
  appealWithDetailSelector,
  tasksForAppealAssignedToAttorneySelector,
  tasksForAppealAssignedToUserSelector
} from '../selectors';

import { buildCaseReviewPayload } from '../utils';
import { requestSave } from '../uiReducer/uiActions';
import {
  deleteAppeal,
  checkoutStagedAppeal,
  stageAppeal,
  setCaseReviewActionType,
  initialAssignTasksToUser,
  reassignTasksToUser
} from '../QueueActions';
import {
  dropdownStyling,
  JUDGE_DECISION_OPTIONS
} from '../constants';
import AssignWidget from './AssignWidget';
import type { Task, Appeal } from '../types/models';
import type { State } from '../types/state';

const ASSIGN = 'ASSIGN';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // From store
  appeal: Appeal,
  task: Task,
  changedAppeals: Array<string>,
  decision: Object,
  userRole: string,
  // Action creators
  requestSave: typeof requestSave,
  deleteAppeal: typeof deleteAppeal,
  checkoutStagedAppeal: typeof checkoutStagedAppeal,
  stageAppeal: typeof stageAppeal,
  setCaseReviewActionType: typeof setCaseReviewActionType,
  initialAssignTasksToUser: typeof initialAssignTasksToUser,
  reassignTasksToUser: typeof reassignTasksToUser,
  // From withRouter
  history: Object
|};

type ComponentState = {
  selectedOption: ?{
    label: string,
    value: string
  }
};

// todo: make StartCheckoutFlowDropdownBase
class JudgeActionsDropdown extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = { selectedOption: null };
  }

  handleChange = (option) => {
    this.setState({ selectedOption: option });

    if (option.value === ASSIGN) {
      return;
    }

    const {
      appeal,
      task,
      appealId,
      history,
      decision,
      userRole
    } = this.props;
    const actionType = option.value;

    this.props.setCaseReviewActionType(actionType);

    if (actionType === DECISION_TYPES.OMO_REQUEST) {
      const payload = buildCaseReviewPayload(decision, userRole, appeal.issues, {
        location: 'omo_office',
        attorney_id: task.assignedBy.pgId
      });
      const successMsg = sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteranFullName);

      this.props.requestSave(`/case_reviews/${task.taskId}/complete`, payload, { title: successMsg }).
        then(() => {
          history.push('');
          history.replace('/queue');
          this.props.deleteAppeal(appealId);
        });
    } else {
      this.props.stageAppeal(appealId);

      history.push('');
      history.replace(`/queue/appeals/${appealId}/dispositions`);
    }
  }

  handleAssignment =
    ({ tasks, assigneeId, previousAssigneeId }:
      { tasks: Array<Task>, assigneeId: string, previousAssigneeId: string}) => {
      if (tasks[0].taskType === 'Assign') {
        return this.props.initialAssignTasksToUser({ tasks,
          assigneeId,
          previousAssigneeId });
      }

      return this.props.reassignTasksToUser({ tasks,
        assigneeId,
        previousAssigneeId });

    }

  assignWidgetVisible = () => {
    const { selectedOption } = this.state;

    return selectedOption && selectedOption.value === ASSIGN;
  }

  render = () => {
    const {
      task
    } = this.props;
    const options = [];

    if (task.taskType === 'Review') {
      options.push(DECASS_WORK_PRODUCT_TYPES.OMO_REQUEST.includes(task.workProduct) ?
        JUDGE_DECISION_OPTIONS.OMO_REQUEST :
        JUDGE_DECISION_OPTIONS.DRAFT_DECISION);
    } else {
      options.push({ label: 'Assign to attorney',
        value: ASSIGN });
    }

    return <React.Fragment>
      <SearchableDropdown
        placeholder="Select an action&hellip;"
        name={`start-checkout-flow-${this.props.appealId}`}
        options={options}
        onChange={this.handleChange}
        hideLabel
        dropdownStyling={dropdownStyling}
        value={this.state.selectedOption} />
      {this.assignWidgetVisible() &&
        <AssignWidget
          onTaskAssignment={this.handleAssignment}
          previousAssigneeId={task.assignedTo.id.toString()}
          selectedTasks={[task]} />}
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => ({
  appeal: appealWithDetailSelector(state, { appealId: ownProps.appealId }),
  task: tasksForAppealAssignedToAttorneySelector(state, ownProps)[0] ||
    tasksForAppealAssignedToUserSelector(state, ownProps)[0],
  changedAppeals: Object.keys(state.queue.stagedChanges.appeals),
  decision: state.queue.stagedChanges.taskDecision,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  deleteAppeal,
  checkoutStagedAppeal,
  stageAppeal,
  setCaseReviewActionType,
  initialAssignTasksToUser,
  reassignTasksToUser
}, dispatch);

export default (
  withRouter(
    connect(mapStateToProps, mapDispatchToProps)(JudgeActionsDropdown)): React.ComponentType<Params>);
