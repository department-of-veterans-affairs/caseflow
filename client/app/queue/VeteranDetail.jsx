import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import React from 'react';
import { get } from 'lodash';

import { DateString } from '../util/DateUtil';
import { appealWithDetailSelector } from './selectors';
import { detailListStyling, getDetailField } from './Detail';
import { getAppealValue } from './QueueActions';
import Address from './components/Address';
import BareList from '../components/BareList';
import { AppealHasSubstitutionAlert } from './substituteAppellant/caseDetails/AppealHasSubstitutionAlert';
import COPY from '../../COPY';

/**
 * A component to display various details about the veteran including name, gender, date of birth, date of death,
 * address and email.
 */
export const VeteranDetail = ({ veteran, substitutionAppealId, stateOnly }) => {
  const {
    address,
    full_name: fullName,
    gender,
    date_of_birth: dob,
    date_of_death: dod,
    email_address: email
  } = veteran;

  if (stateOnly) {
    return <>{address?.state}</>;
  }

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
      value: <DateString date={dod} inputFormat="YYYY-MM-DD" dateFormat="M/D/YYYY" />
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
    <>
      <div {...detailListStyling}>
        <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
        <p><em>{COPY.CASE_DETAILS_VETERAN_ADDRESS_SOURCE}</em></p>
        {substitutionAppealId && <AppealHasSubstitutionAlert targetAppealId={substitutionAppealId} />}
      </div>
    </>
  );
};

VeteranDetail.propTypes = {

  /**
   * Determines whether to display alert regarding presence of substitution appeal
   */
  substitutionAppealId: PropTypes.string,

  /**
   * Veteran object returned from the back end
   */
  veteran: PropTypes.shape({
    address: PropTypes.shape({
      state: PropTypes.string
    }),
    date_of_birth: PropTypes.string,
    date_of_death: PropTypes.string,
    email_address: PropTypes.string,
    full_name: PropTypes.string,
    gender: PropTypes.string
  }),

  /**
   * Whether or not to display only the veteran's state of residence
   */
  stateOnly: PropTypes.bool
};

const mapStateToProps = (state, ownProps) => {
  const loadingVeteranInfo = get(state.queue.loadingAppealDetail[ownProps.appealId], 'veteranInfo');

  if (loadingVeteranInfo?.loading) {
    return { loading: true };
  }

  const appeal = appealWithDetailSelector(state, { appealId: ownProps.appealId });

  return {
    veteranInfo: appeal?.veteranInfo,
    substitutions: appeal?.substitutions,
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
      veteranInfo: PropTypes.object,
      substitutions: PropTypes.arrayOf(PropTypes.object),
      stateOnly: PropTypes.bool
    }

    componentDidMount = () => {
      if (!this.props.veteranInfo) {
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

      return (
        <WrappedComponent
          stateOnly={this.props.stateOnly}
          substitutionAppealId={this.props.substitutions?.[0]?.target_appeal_uuid} // eslint-disable-line camelcase
          {...this.props.veteranInfo}
        />
      );
    }
  }
);

export const UnconnectedVeteranDetail = wrapVeteranDetailComponent(VeteranDetail);
export default connect(mapStateToProps, mapDispatchToProps)(UnconnectedVeteranDetail);
