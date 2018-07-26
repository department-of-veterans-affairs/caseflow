import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  setCaseReviewActionType,
  resetDecisionOptions,
  checkoutStagedAppeal,
  stageAppeal
} from '../QueueActions';
import {
  dropdownStyling,
  DRAFT_DECISION_OPTIONS
} from '../constants';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES.json';

class SelectCheckoutFlowDropdown extends React.PureComponent {
  changeRoute = (props) => {
    const {
      appealId,
      history
    } = this.props;
    const decisionType = props.value;
    const route = decisionType === DECISION_TYPES.OMO_REQUEST ? 'submit' : 'dispositions';

    this.stageAppeal();

    this.props.resetDecisionOptions();
    this.props.setCaseReviewActionType(decisionType);

    history.push('');
    history.replace(`/queue/appeals/${appealId}/${route}`);
  };

  stageAppeal = () => {
    const { appealId } = this.props;

    if (this.props.changedAppeals.includes(appealId)) {
      this.props.checkoutStagedAppeal(appealId);
    }

    this.props.stageAppeal(appealId);
  }

  render = () => <SearchableDropdown
    name={`start-checkout-flow-${this.props.appealId}`}
    placeholder="Select an action&hellip;"
    options={DRAFT_DECISION_OPTIONS}
    onChange={this.changeRoute}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

SelectCheckoutFlowDropdown.propTypes = {
  appealId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.appeals[ownProps.appealId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCaseReviewActionType,
  resetDecisionOptions,
  checkoutStagedAppeal,
  stageAppeal
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SelectCheckoutFlowDropdown));
