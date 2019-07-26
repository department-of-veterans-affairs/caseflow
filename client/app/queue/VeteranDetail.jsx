import React from 'react';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import Address from './components/Address';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { boldText } from './constants';
import { DateString } from '../util/DateUtil';
import { getAppealValue } from './QueueActions';
import { appealWithDetailSelector } from './selectors';
import COPY from '../../COPY.json';

const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});

export class VeteranDetail extends React.PureComponent {
  componentDidMount = () => {
    this.props.getAppealValue(
      this.props.appeal.externalId,
      'veteran',
      'veteranInfo'
    );
  }

  getDetails = () => {
    const {
      address,
      full_name,
      gender,
      date_of_birth: dob,
      date_of_death: dod,
      email_address
    } = this.props.veteranInfo.veteran;

    const details = [{
      label: 'Name',
      value: full_name
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

    if (email_address) {
      details.push({
        label: 'Email Address',
        value: email_address
      });
    }

    const getDetailField = ({ label, value }) => () => <React.Fragment>
      <span {...boldText}>{label}:</span> {value}
    </React.Fragment>;

    return <BareList ListElementComponent="ul" items={details.map(getDetailField)} />;
  };

  getDataSourceInfo = () => {
    return <p><em>{COPY.CASE_DETAILS_VETERAN_ADDRESS_SOURCE}</em></p>;
  }

  render = () => {
    if (!this.props.veteranInfo) {
      if (this.props.loading) {
        return <React.Fragment>{COPY.CASE_DETAILS_LOADING}</React.Fragment>;
      }
      if (this.props.error) {
        return <React.Fragment>
          {COPY.CASE_DETAILS_UNABLE_TO_LOAD}
        </React.Fragment>;
      }

      return null;
    }

    return <ul {...detailListStyling}>
      {this.getDetails()}
      {this.getDataSourceInfo()}
    </ul>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const loadingVeteranInfo = _.get(state.queue.loadingAppealDetail[ownProps.appealId], 'veteranInfo');
  const appeal = appealWithDetailSelector(state, { appealId: ownProps.appeal.externalId });

  return {
    veteranInfo: appeal.veteranInfo,
    loading: loadingVeteranInfo ? loadingVeteranInfo.loading : null,
    error: loadingVeteranInfo ? loadingVeteranInfo.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getAppealValue
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(VeteranDetail));

