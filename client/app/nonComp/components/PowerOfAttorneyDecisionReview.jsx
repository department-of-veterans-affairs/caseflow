import { bindActionCreators } from 'redux';
import { connect, shallowEqual, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';


import COPY from '../../../COPY';
import PowerOfAttorneyDetailUnconnected from '../../queue/PowerOfAttorneyDetail';

/**
 * Returns a selector to fetch the power of attorney details from the Redux state.
 * @param {Object} appealId -- The appeal's external id
 * @returns {function} -- A function that selects the power of attorney from the Redux state.
 */
const powerOfAttorneyFromAppealSelector = (appealId) =>
  (state) => {
    console.log(state);

    return {
      appellantType: state.appeal?.claimantType,
      powerOfAttorney: state.task?.power_of_attorney,
      loading: false,
      // error: loadingPowerOfAttorney?.error
      error: false, //todo -
      poaAlert: state.poaAlert
    };
  }
  ;

/**
 * Wraps a component with logic to fetch the power of attorney data from the API.
 * @param {Object} WrappedComponent -- The component being wrapped / The display component.
 * @returns {Component} -- The wrapped component.
 */
const powerOfAttorneyDecisionReviewWrapper = (WrappedComponent) => {
  const wrappedComponent = ({ appealId }) => {
    const { error, loading, powerOfAttorney, appellantType, poaAlert } = useSelector(
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

      // getAppealValueRedux(appealId, 'power_of_attorney', 'powerOfAttorney');

      return null;
    }

    return <WrappedComponent
      powerOfAttorney={powerOfAttorney}
      appealId={appealId}
      poaAlert={poaAlert}
      appellantType={appellantType}
    />;
  };

  wrappedComponent.propTypes = {
    appealId: PropTypes.string,
    getAppealValue: PropTypes.func,
    appellantType: PropTypes.string,
    poaAlert: PropTypes.shape({
      alertType: PropTypes.string,
      message: PropTypes.string,
      powerOfAttorney: PropTypes.object
    })
  };

  return wrappedComponent;
};

export default powerOfAttorneyDecisionReviewWrapper(PowerOfAttorneyDetailUnconnected);
