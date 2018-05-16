import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { withRouter } from 'react-router-dom';

import SearchableDropdown from '../../components/SearchableDropdown';

import {
  dropdownStyling,
  JUDGE_DECISION_OPTIONS
} from '../constants';

class JudgeStartCheckoutFlowDropdown extends React.PureComponent {
  render = () => <SearchableDropdown
    placeholder="Select an action&hellip;"
    name={`start-checkout-flow-${this.props.vacolsId}`}
    options={JUDGE_DECISION_OPTIONS}
    hideLabel
    onChange={_.noop}
    dropdownStyling={dropdownStyling} />
}

JudgeStartCheckoutFlowDropdown.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId]
});

export default withRouter(connect(mapStateToProps)(JudgeStartCheckoutFlowDropdown));
