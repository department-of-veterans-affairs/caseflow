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
import { resetBreadcrumbs } from '../uiReducer/uiActions';
import {
  dropdownStyling,
  DECISION_TYPES,
  DRAFT_DECISION_OPTIONS
} from '../constants';

class SelectCheckoutFlowDropdown extends React.PureComponent {
  changeRoute = (props) => {
    const {
      vacolsId,
      history,
      appeal: { attributes: { veteran_full_name: vetName } }
    } = this.props;
    const decisionType = props.value;
    const route = decisionType === DECISION_TYPES.OMO_REQUEST ? 'submit' : 'dispositions';

    this.stageAppeal(decisionType);

    this.props.resetDecisionOptions();
    this.props.setCaseReviewActionType(decisionType);
    this.props.resetBreadcrumbs(vetName, vacolsId);

    history.push('');
    history.replace(`/queue/appeals/${vacolsId}/${route}`);
  };

  stageAppeal = (decisionType) => {
    const {
      vacolsId,
      appeal: { attributes: { issues } }
    } = this.props;

    if (this.props.changedAppeals.includes(vacolsId)) {
      this.props.checkoutStagedAppeal(vacolsId);
    }

    if (decisionType === DECISION_TYPES.DRAFT_DECISION) {
      this.props.stageAppeal(vacolsId, {
        issues: _.map(issues, (issue) => _.set(issue, 'disposition', null))
      });
    } else {
      this.props.stageAppeal(vacolsId);
    }
  }

  render = () => <SearchableDropdown
    name={`start-checkout-flow-${this.props.vacolsId}`}
    placeholder="Select an action&hellip;"
    options={DRAFT_DECISION_OPTIONS}
    onChange={this.changeRoute}
    hideLabel
    dropdownStyling={dropdownStyling} />;
}

SelectCheckoutFlowDropdown.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  changedAppeals: _.keys(state.queue.stagedChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCaseReviewActionType,
  resetDecisionOptions,
  checkoutStagedAppeal,
  stageAppeal,
  resetBreadcrumbs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(SelectCheckoutFlowDropdown));
