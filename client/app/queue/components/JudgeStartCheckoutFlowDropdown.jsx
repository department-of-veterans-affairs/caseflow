import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';
import COPY from '../../../COPY.json';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  requestSave,
  saveSuccess,
  resetBreadcrumbs
} from '../uiReducer/uiActions';
import {
  deleteAppeal,
  checkoutStagedAppeal,
  stageAppeal,
  setCaseReviewActionType
} from '../QueueActions';
import {
  dropdownStyling,
  DECISION_OPTIONS,
  DECISION_TYPES
} from '../constants';

// todo: make StartCheckoutFlowDropdownBase
class JudgeStartCheckoutFlowDropdown extends React.PureComponent {
  changeRoute = (props) => {
    const {
      appeal: { attributes: appeal },
      vacolsId,
      history
    } = this.props;
    const actionType = props.value;

    this.props.setCaseReviewActionType(actionType);

    if (actionType === DECISION_TYPES.JUDGE.OMO_REQUEST) {
      history.push('');
      history.replace('/queue');

      // this.props.requestSave()...
      this.props.deleteAppeal(vacolsId);
      this.props.saveSuccess(sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteran_full_name));
    } else {
      this.props.resetBreadcrumbs(appeal.veteran_full_name, vacolsId);
      this.stageAppeal();

      history.push('');
      history.replace(`/queue/appeals/${vacolsId}/dispositions`);
    }
  }

  stageAppeal = () => {
    const { vacolsId } = this.props;

    if (this.props.changedAppeals.includes(vacolsId)) {
      this.props.checkoutStagedAppeal(vacolsId);
    }

    this.props.stageAppeal(vacolsId);
  }

  render = () => <SearchableDropdown
    placeholder="Select an action&hellip;"
    name={`start-checkout-flow-${this.props.vacolsId}`}
    options={DECISION_OPTIONS.JUDGE}
    onChange={this.changeRoute}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

JudgeStartCheckoutFlowDropdown.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  changedAppeals: Object.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  saveSuccess,
  deleteAppeal,
  checkoutStagedAppeal,
  stageAppeal,
  resetBreadcrumbs,
  setCaseReviewActionType
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(JudgeStartCheckoutFlowDropdown));
