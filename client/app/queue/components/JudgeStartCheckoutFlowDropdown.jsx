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
  setCaseReviewActionType
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
  saveSuccess: typeof saveSuccess,
  deleteAppeal: typeof deleteAppeal,
  checkoutStagedAppeal: typeof checkoutStagedAppeal,
  stageAppeal: typeof stageAppeal,
  setCaseReviewActionType: typeof setCaseReviewActionType,
  // From withRouter
  history: Object
|};

type ComponentState = {
  assignWidgetVisible: boolean
};

// todo: make StartCheckoutFlowDropdownBase
class JudgeStartCheckoutFlowDropdown extends React.PureComponent<Props, ComponentState> {
  constructor(props) {
    super(props);

    this.state = { assignWidgetVisible: false };
  }

  handleChange = (option) => {
    if (option.value === ASSIGN) {
      this.setState({ assignWidgetVisible: true });

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

  render = () => {
    const {
      task
    } = this.props;
    const options = [];
    if (task.attributes.task_type === 'Review') {
      options.push(DECASS_WORK_PRODUCT_TYPES.OMO_REQUEST.includes(task.attributes.work_product) ?
        JUDGE_DECISION_OPTIONS.OMO_REQUEST :
        JUDGE_DECISION_OPTIONS.DRAFT_DECISION);
    }
    options.push({ label: 'Assign to attorney',
      value: ASSIGN });

    return <React.Fragment>
      <SearchableDropdown
        placeholder="Select an action&hellip;"
        name={`start-checkout-flow-${this.props.appealId}`}
        options={options}
        onChange={this.handleChange}
        hideLabel
        dropdownStyling={dropdownStyling} />
      {this.state.assignWidgetVisible &&
        <AssignWidget onTaskAssignment={() => {}} previousAssigneeId={'0'} selectedTasks={[task]} />}
    </React.Fragment>;
  }
}

JudgeStartCheckoutFlowDropdown.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state: State, ownProps: Params) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.appealId],
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
  setCaseReviewActionType
}, dispatch);

export default (
  withRouter(connect(mapStateToProps, mapDispatchToProps)(JudgeStartCheckoutFlowDropdown)): React.ComponentType<Params>);
