import { bindActionCreators } from 'redux';
import { connect, shallowEqual, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { appealWithDetailSelector } from './selectors';
import { detailListStyling, getDetailField } from './Detail';
import { getAppealValue } from './QueueActions';
import Address from './components/Address';
import BareList from '../components/BareList';
import { PoaRefresh } from './components/PoaRefresh';
import COPY from '../../COPY';

/**
 * Returns a selector to fetch the power of attorney details from the Redux state.
 * @param {Object} appealId -- The appeal's external id
 * @returns {function} -- A function that selects the power of attorney from the Redux state.
 */
const powerOfAttorneyFromAppealSelector = (appealId) =>
  (state) => {
    const loadingPowerOfAttorney = _.get(state.queue.loadingAppealDetail[appealId], 'powerOfAttorney');

    if (loadingPowerOfAttorney?.loading) {
      return { loading: true };
    }

    const appeal = appealWithDetailSelector(state, { appealId });

    return {
      powerOfAttorney: appeal?.powerOfAttorney,
      loading: false,
      error: loadingPowerOfAttorney?.error
    };
  }
;

/**
 * Wraps a component with logic to fetch the power of attorney data from the API.
 * @param {Object} WrappedComponent -- The component being wrapped / The display component.
 * @returns {Component} -- The wrapped component.
 */
const PowerOfAttorneyDetailWrapper = (WrappedComponent) => {
  const wrappedComponent = ({ appealId, getAppealValue: getAppealValueRedux }) => {
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

      getAppealValueRedux(appealId, 'power_of_attorney', 'powerOfAttorney');

      return null;
    }

    const hasPowerOfAttorneyDetails = powerOfAttorney.representative_type && powerOfAttorney.representative_name;

    return hasPowerOfAttorneyDetails ?
      <WrappedComponent powerOfAttorney={powerOfAttorney} /> :
      <p><em>{COPY.CASE_DETAILS_NO_POA}</em></p>;
  };

  wrappedComponent.propTypes = {
    appealId: PropTypes.string,
    getAppealValue: PropTypes.func
  };

  return wrappedComponent;
};

/**
 * Component that displays just the power of attorney's name.
 */
export const PowerOfAttorneyNameUnconnected = ({ powerOfAttorney }) => (
  <React.Fragment>{powerOfAttorney.representative_name}</React.Fragment>
);

/**
 * Component that displays details about the power of attorney.
 */
export const PowerOfAttorneyDetailUnconnected = ({ powerOfAttorney }) => {
  const details = [
    {
      label: powerOfAttorney.representative_type,
      value: powerOfAttorney.representative_name
    }
  ];

  if (powerOfAttorney.representative_address) {
    details.push({
      label: 'Address',
      value: <Address address={powerOfAttorney.representative_address} />
    });
  }

  if (powerOfAttorney.representative_email_address) {
    details.push({
      label: 'Email Address',
      value: powerOfAttorney.representative_email_address
    });
  }

  return (
    <div>
      <p><em>{ powerOfAttorney.representative_type === 'Unrecognized representative' ?
        COPY.CASE_DETAILS_UNRECOGNIZED_POA :
        <PoaRefresh powerOfAttorney={powerOfAttorney} {...detailListStyling} />}</em></p>
      <ul {...detailListStyling}>
        <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
      </ul>
    </div>
  );
};

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
