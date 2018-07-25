// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import COPY from '../../../COPY.json';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES.json';
import DECASS_WORK_PRODUCT_TYPES from '../../../constants/DECASS_WORK_PRODUCT_TYPES.json';

import SearchableDropdown from '../../components/SearchableDropdown';

import { buildCaseReviewPayload } from '../utils';
import {
  requestSave,
  saveSuccess
} from '../uiReducer/uiActions';
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
import type { Task, LegacyAppeal } from '../types/models';
import type { State } from '../types/state';

const ASSIGN = 'ASSIGN';

type Params = {|
  appealId: string
|};

type Props = Params & {|
  // From store
  appeal: LegacyAppeal,
  task: Task,
  changedAppeals: Array<string>,
  decision: Object,
  userRole: string,
  // Action creators
  requestSave: typeof requestSave,
  saveSuccess: typeof saveSuccess,
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
      appeal: { attributes: appeal },
      task,
      appealId,
      history,
      decision,
      userRole
    } = this.props;
    const actionType = option.value;

    this.props.setCaseReviewActionType(actionType);

    if (actionType === DECISION_TYPES.OMO_REQUEST) {
      const payload = buildCaseReviewPayload(decision, userRole, appeal.issues, { location: 'omo_office' });
      const successMsg = sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteran_full_name);

      this.props.requestSave(`/case_reviews/${task.attributes.task_id}/complete`, payload, successMsg).
        then(() => {
          this.props.deleteAppeal(appealId);
          history.push('');
          history.replace('/queue');
        });
    } else {
      this.stageAppeal();

      history.push('');
      history.replace(`/queue/appeals/${appealId}/dispositions`);
    }
  }

  stageAppeal = () => {
    const { appealId } = this.props;

    if (this.props.changedAppeals.includes(appealId)) {
      this.props.checkoutStagedAppeal(appealId);
    }

    this.props.stageAppeal(appealId);
  }

  handleAssignment =
    ({ tasks, assigneeId, previousAssigneeId }:
      { tasks: Array<Task>, assigneeId: string, previousAssigneeId: string}) => {
      if (tasks[0].attributes.task_type === 'Assign') {
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

    if (task.attributes.task_type === 'Review') {
      options.push(DECASS_WORK_PRODUCT_TYPES.OMO_REQUEST.includes(task.attributes.work_product) ?
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
          previousAssigneeId={task.attributes.assigned_to_pg_id.toString()}
          selectedTasks={[task]} />}
    </React.Fragment>;
  }
}

JudgeActionsDropdown.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state: State, ownProps: Params) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  task: state.queue.tasks[ownProps.appealId],
  changedAppeals: Object.keys(state.queue.stagedChanges.appeals),
  decision: state.queue.stagedChanges.taskDecision,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  saveSuccess,
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
