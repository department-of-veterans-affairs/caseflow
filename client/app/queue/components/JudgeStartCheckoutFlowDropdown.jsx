import React from 'react';
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

// todo: make StartCheckoutFlowDropdownBase
class JudgeStartCheckoutFlowDropdown extends React.PureComponent {
  changeRoute = (props) => {
    const {
      appeal: { attributes: appeal },
      task,
      appealId,
      history,
      decision,
      userRole
    } = this.props;
    const actionType = props.value;

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
      task: { attributes: task }
    } = this.props;
    const dropdownOption = DECASS_WORK_PRODUCT_TYPES.OMO_REQUEST.includes(task.work_product) ?
      JUDGE_DECISION_OPTIONS.OMO_REQUEST :
      JUDGE_DECISION_OPTIONS.DRAFT_DECISION;

    return <SearchableDropdown
      placeholder="Select an action&hellip;"
      name={`start-checkout-flow-${this.props.appealId}`}
      options={[dropdownOption]}
      onChange={this.changeRoute}
      hideLabel
      dropdownStyling={dropdownStyling} />;
  }
}

JudgeStartCheckoutFlowDropdown.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
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
  setCaseReviewActionType
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(JudgeStartCheckoutFlowDropdown));
