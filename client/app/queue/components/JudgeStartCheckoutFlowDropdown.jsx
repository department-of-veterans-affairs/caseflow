import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import { withRouter } from 'react-router-dom';
import { sprintf } from 'sprintf-js';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  requestSave,
  saveSuccess
} from '../uiReducer/uiActions';
import { deleteAppeal } from '../QueueActions';
import {
  dropdownStyling,
  JUDGE_DECISION_OPTIONS,
  JUDGE_DECISION_TYPES
} from '../constants';

class JudgeStartCheckoutFlowDropdown extends React.PureComponent {
  changeRoute = (props) => {
    const {
      appeal: { attributes: appeal },
      vacolsId
    } = this.props;
    const actionType = props.value;

    if (actionType === JUDGE_DECISION_TYPES.OMO_REQUEST) {
      // this.props.requestSave()...
      this.props.deleteAppeal(vacolsId);
      this.props.saveSuccess(sprintf(COPY.JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE, appeal.veteran_full_name));
    } else {
      // todo: go to review dispositions
    }
  }

  render = () => <SearchableDropdown
    placeholder="Select an action&hellip;"
    name={`start-checkout-flow-${this.props.vacolsId}`}
    options={JUDGE_DECISION_OPTIONS}
    hideLabel
    onChange={this.changeRoute}
    dropdownStyling={dropdownStyling} />
}

JudgeStartCheckoutFlowDropdown.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId]
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  saveSuccess,
  deleteAppeal
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(JudgeStartCheckoutFlowDropdown));
