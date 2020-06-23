import { bindActionCreators } from 'redux';
import { connect, shallowEqual, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { appealWithDetailSelector } from './selectors';
import { getAppealValue } from './QueueActions';
import Address from './components/Address';
import COPY from '../../COPY';

/**
 * Returns a selector to fetch the power of attorney details from the Redux state.
 * @param {Object} appealId -- The appeal's external id
 * @returns {function} -- A function that selects the power of attorney from the Redux state.
 */
const powerOfAttorneyFromAppealSelector = (appealId) => (
  (state) => {
    const loadingPowerOfAttorney = _.get(state.queue.loadingAppealDetail[appealId], 'powerOfAttorney');

    if (loadingPowerOfAttorney?.loading) {
      return { loading: true };
    }

    const appeal = appealWithDetailSelector(state, { appealId: appealId });

    return {
      powerOfAttorney: appeal?.powerOfAttorney,
      loading: false,
      error: loadingPowerOfAttorney?.error
    }
  }
);

/**
 * Wraps a component with logic to fetch the power of attorney data from the API.
 * @param {Object} WrappedComponent -- The component being wrapped / The display component.
 * @returns {Component} -- The wrapped component.
 */
const PowerOfAttorneyDetailWrapper = (WrappedComponent) => (
  ({ appealId, getAppealValue }) => {
    const { error, loading, powerOfAttorney } = useSelector(
      powerOfAttorneyFromAppealSelector(appealId),
      shallowEqual
    );

    if (!powerOfAttorney) {
      if (loading) {
        return <React.Fragment>{COPY.CASE_DETAILS_LOADING}</React.Fragment>;
      }

      if (error) {
        return <React.Fragment>{COPY.CASE_DETAILS_UNABLE_TO_LOAD}</React.Fragment>;
      }

      getAppealValue(appealId, 'power_of_attorney', 'powerOfAttorney');

      return null;
    }

    const hasPowerOfAttorneyDetails = powerOfAttorney.representative_type && powerOfAttorney.representative_name;

    if (!hasPowerOfAttorneyDetails) {
      return <p><em>{COPY.CASE_DETAILS_NO_POA}</em></p>;
    }

    return <WrappedComponent powerOfAttorney={powerOfAttorney} />;
  }
);

PowerOfAttorneyDetailWrapper.propTypes = {
  appealId: PropTypes.string,
  getAppealValue: PropTypes.func,
};

const PowerOfAttorneyNameUnconnected = ({ powerOfAttorney }) => (
  <React.Fragment>{powerOfAttorney.representative_name}</React.Fragment>
);

const PowerOfAttorneyDetailUnconnected = ({ powerOfAttorney }) => (
  <span>
    <p>
      <strong>{powerOfAttorney.representative_type}:</strong> {powerOfAttorney.representative_name}
    </p>
    {powerOfAttorney.representative_address &&
      <p>
        <strong>Address:</strong> <Address address={powerOfAttorney.representative_address} />
      </p>
    }
    {powerOfAttorney.representative_email_address &&
      <p>
        <strong>Email Address:</strong> {powerOfAttorney.representative_email_address}
      </p>
    }
    <p><em>{COPY.CASE_DETAILS_INCORRECT_POA}</em></p>
  </span>
);

PowerOfAttorneyNameUnconnected.propTypes = PowerOfAttorneyDetailUnconnected.propTypes = {
  powerOfAttorney: PropTypes.shape({
    representative_type: PropTypes.string,
    representative_name: PropTypes.string,
    representative_address: PropTypes.object,
    representative_email_address: PropTypes.string
  })
};

const mapDispatchToProps = (dispatch) => bindActionCreators(
  {
    getAppealValue
  },
  dispatch
);

export const PowerOfAttorneyName = _.flow(
  PowerOfAttorneyDetailWrapper,
  connect(null, mapDispatchToProps)
)(PowerOfAttorneyNameUnconnected);

export default _.flow(
  PowerOfAttorneyDetailWrapper,
  connect(null, mapDispatchToProps)
)(PowerOfAttorneyDetailUnconnected);
