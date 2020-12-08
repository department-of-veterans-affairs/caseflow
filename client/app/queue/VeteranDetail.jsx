import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { DateString } from '../util/DateUtil';
import { appealWithDetailSelector } from './selectors';
import { detailListStyling, getDetailField } from './Detail';
import { getAppealValue } from './QueueActions';
import Address from './components/Address';
import BareList from '../components/BareList';
import COPY from '../../COPY';

/**
 * A component to display the state a veteran resides in.
 *
 * @param {Object} veteran An object containing information about the veteran, including their adress and state.
 */
const VeteranState = ({ veteran }) => {
  const state = veteran?.address?.state;

  if (state) {
    return <>{state}</>;
  }

  return null;
};

/**
 * A component to display various details about the veteran including name, gender, date of birth, date of death,
 * address and email.
 *
 * @param {Object} veteran An object containing information about the veteran, including their adress and state.
 */
const VeteranDetail = ({ veteran }) => {
  const {
    address,
    full_name: fullName,
    gender,
    date_of_birth: dob,
    date_of_death: dod,
    email_address: email
  } = veteran;

  const details = [{
    label: 'Name',
    value: fullName
  }];

  const genderValue = gender === 'F' ? COPY.CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE :
    COPY.CASE_DETAILS_GENDER_FIELD_VALUE_MALE;

  if (genderValue) {
    details.push({
      label: COPY.CASE_DETAILS_GENDER_FIELD_LABEL,
      value: genderValue
    });
  }

  if (dob) {
    details.push({
      label: 'Date of birth',
      value: <DateString date={dob} inputFormat="MM/DD/YYYY" dateFormat="M/D/YYYY" />
    });
  }

  if (dod) {
    details.push({
      label: 'Date of death',
      value: <DateString date={dod} inputFormat="MM/DD/YYYY" dateFormat="M/D/YYYY" />
    });
  }

  if (address) {
    details.push({
      label: 'Mailing Address',
      value: <Address address={address} />
    });
  }

  if (email) {
    details.push({
      label: 'Email Address',
      value: email
    });
  }

  return (
    <ul {...detailListStyling}>
      <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
      <p><em>{COPY.CASE_DETAILS_VETERAN_ADDRESS_SOURCE}</em></p>
    </ul>
  );
};

VeteranState.propTypes = VeteranDetail.propTypes = {
  veteran: PropTypes.shape({
    address: PropTypes.shape({
      state: PropTypes.string
    }),
    date_of_birth: PropTypes.string,
    date_of_death: PropTypes.string,
    email_address: PropTypes.string,
    full_name: PropTypes.string,
    gender: PropTypes.string
  })
};

const mapStateToProps = (state, ownProps) => {
  const loadingVeteranInfo = _.get(state.queue.loadingAppealDetail[ownProps.appealId], 'veteranInfo');

  if (loadingVeteranInfo?.loading) {
    return { loading: true };
  }

  const appeal = appealWithDetailSelector(state, { appealId: ownProps.appealId });

  return {
    veteranInfo: appeal?.veteranInfo,
    loading: !appeal,
    error: loadingVeteranInfo?.error
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getAppealValue
}, dispatch);

/**
 * Wrapper for veteran components that handles requesting veteran information from the back end, displaying a loading
 * icon while waiting, an error if it exists, and finally the wrapped component
 *
 * Uses this pattern for higher order components: https://reactjs.org/docs/higher-order-components.html
 */
const wrapVeteranDetailComponent = (WrappedComponent) => (
  class extends React.PureComponent {
    static propTypes = {
      appealId: PropTypes.string,
      error: PropTypes.object,
      getAppealValue: PropTypes.func,
      loading: PropTypes.bool,
      veteranInfo: PropTypes.object
    }

    componentDidMount = () => {
      if (!this.props.veteranInfo && this.props.getAppealValue) {
        this.props.getAppealValue(this.props.appealId, 'veteran', 'veteranInfo');
      }
    }

    render() {
      if (!this.props.veteranInfo) {
        if (this.props.loading) {
          return <>{COPY.CASE_DETAILS_LOADING}</>;
        }

        if (this.props.error) {
          return <>{COPY.CASE_DETAILS_UNABLE_TO_LOAD}</>;
        }

        return null;
      }

      return <WrappedComponent {...this.props.veteranInfo} />;
    }
  }
);

export const UnconnectedVeteranState = wrapVeteranDetailComponent(VeteranState);
export const UnconnectedVeteranDetail = wrapVeteranDetailComponent(VeteranDetail);

export const VeteranStateDetail = _.flow(
  UnconnectedVeteranState,
  connect(mapStateToProps, mapDispatchToProps)
);

export default _.flow(
  UnconnectedVeteranDetail,
  connect(mapStateToProps, mapDispatchToProps)
);
