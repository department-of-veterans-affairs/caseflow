import { bindActionCreators } from 'redux';
import { connect, shallowEqual, useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import COPY from '../../../COPY';
import PowerOfAttorneyDetailUnconnected from '../../queue/PowerOfAttorneyDetail';
import { getPoAValue } from '../actions/task';

/**
 * returns different props required for the Original Component.
 * @param
 * @returns {function} -- A function that selects the power of attorney from the Redux state.
 */
const powerOfAttorneyFromNonCompState = () =>
  (state) => {
    return {
      appellantType: state.appeal?.claimantType,
      /* eslint-disable-next-line camelcase */
      powerOfAttorney: state.task?.power_of_attorney,
      loading: state?.loadingPowerOfAttorney?.loading,
      error: state?.loadingPowerOfAttorney?.error,
      poaAlert: state.poaAlert,
      taskId: state.task?.id
    };
  }
  ;

/**
 * Wraps a component with logic to fetch the power of attorney data from the API.
 * @param {Object} WrappedComponent -- The component being wrapped in this case its PowerOfAttorneyDetailUnconnected.
 * @returns {Component} -- HOC component.
 */
const powerOfAttorneyDecisionReviewWrapper = (WrappedComponent) => {
  const wrappedComponent = ({ appealId, getPoAValue: getPoAValueRedux }) => {
    const { error, loading, powerOfAttorney, appellantType, poaAlert, taskId } = useSelector(
      powerOfAttorneyFromNonCompState(),
      shallowEqual
    );

    if (!powerOfAttorney) {
      if (loading) {
        return <React.Fragment>{COPY.CASE_DETAILS_LOADING}</React.Fragment>;
      }

      if (error) {
        return <React.Fragment>{COPY.CASE_DETAILS_UNABLE_TO_LOAD}</React.Fragment>;
      }

      getPoAValueRedux(taskId, 'power_of_attorney');

      return null;
    }

    return <WrappedComponent
      powerOfAttorney={powerOfAttorney}
      appealId={appealId}
      poaAlert={poaAlert}
      appellantType={appellantType}
      vha
    />;
  };

  wrappedComponent.propTypes = {
    appealId: PropTypes.string,
    getPoAValue: PropTypes.func,
    appellantType: PropTypes.string,
    poaAlert: PropTypes.shape({
      alertType: PropTypes.string,
      message: PropTypes.string,
      powerOfAttorney: PropTypes.object
    }),
    vha: PropTypes.bool
  };

  return wrappedComponent;
};

const mapDispatchToProps = (dispatch) => bindActionCreators(
  {
    getPoAValue
  },
  dispatch
);

export default _.flow(
  powerOfAttorneyDecisionReviewWrapper,
  connect(null, mapDispatchToProps)
)(PowerOfAttorneyDetailUnconnected);
