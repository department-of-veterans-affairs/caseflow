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
import Alert from '../components/Alert';

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
      error: loadingPowerOfAttorney?.error,
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
    const poaAlert = useSelector((state) => state.ui.poaAlert);

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
      <WrappedComponent powerOfAttorney={powerOfAttorney} appealId={appealId} poaAlert={poaAlert} /> :
      <p><em>{COPY.CASE_DETAILS_NO_POA}</em></p>;
  };

  wrappedComponent.propTypes = {
    appealId: PropTypes.string,
    getAppealValue: PropTypes.func,
    poaAlert: PropTypes.shape({
      alertType: PropTypes.string,
      message: PropTypes.string,
      powerOfAttorney: PropTypes.object
    })
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
export const PowerOfAttorneyDetailUnconnected = ({ powerOfAttorney, appealId, poaAlert }) => {
  let poa = powerOfAttorney;

  if (poaAlert.powerOfAttorney) {
    poa = poaAlert.powerOfAttorney;
  }
  const details = [
    {
      label: poa.representative_type,
      value: poa.representative_name
    }
  ];

  if (poa.representative_address) {
    details.push({
      label: 'Address',
      value: <Address address={poa.representative_address} />
    });
  }

  if (poa.representative_email_address) {
    details.push({
      label: 'Email Address',
      value: poa.representative_email_address
    });
  }

  return (
    <React.Fragment>
      <div>
        <p>{ poa.representative_type === 'Unrecognized representative' ?
          <em>{ COPY.CASE_DETAILS_UNRECOGNIZED_POA }</em> :
          <PoaRefresh powerOfAttorney={poa} appealId={appealId} {...detailListStyling} />}
        </p>
        <ul {...detailListStyling}>
          <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
        </ul>
        { poaAlert.message && poaAlert.alertType && (
          <div>
            <Alert type={poaAlert.alertType} message={poaAlert.message} scrollOnAlert={false} />
          </div>
        )}
      </div>
    </React.Fragment>
  );
};

PowerOfAttorneyNameUnconnected.propTypes = PowerOfAttorneyDetailUnconnected.propTypes = {
  powerOfAttorney: PropTypes.shape({
    representative_type: PropTypes.string,
    representative_name: PropTypes.string,
    representative_address: PropTypes.object,
    representative_email_address: PropTypes.string,
    representative_id: PropTypes.number
  }),
  poaAlert: PropTypes.shape({
    message: PropTypes.string,
    alertType: PropTypes.string,
    powerOfAttorney: PropTypes.object
  }),
  appealId: PropTypes.number
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
