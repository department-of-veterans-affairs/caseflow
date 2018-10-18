import React from 'react';
import PropTypes from 'prop-types';
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

import type {
  Appeal,
  VeteranInfo
} from './types/models';

const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});

type Params = {|
  appeal: Appeal
|};

type Props = Params & {|
  // state
  veteranInfo: VeteranInfo,
  loading: boolean,
  error: Object,
  // dispatch
  getAppealValue: typeof getAppealValue
|};

export class VeteranDetail extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.getAppealValue(
      this.props.appeal.externalId,
      'veteran',
      'veteranInfo'
    );
  }

  getDetails = () => {
    const details = [{
      label: 'Name',
      value: this.props.veteranInfo.full_name
    }];

    const genderValue = this.props.veteranInfo.gender === 'F' ?
      COPY.CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE :
      COPY.CASE_DETAILS_GENDER_FIELD_VALUE_MALE;

    if (genderValue) {
      details.push({
        label: COPY.CASE_DETAILS_GENDER_FIELD_LABEL,
        value: genderValue
      });
    }
    const dod = this.props.veteranInfo.date_of_birth;

    if (dod) {
      details.push({
        label: 'Date of birth',
        value: <DateString date={dod} inputFormat="MM/DD/YYYY" dateFormat="M/D/YYYY" />
      });
    }
    const address = this.props.veteranInfo.address;

    if (address) {
      details.push({
        label: 'Mailing Address',
        value: <Address address={address} />
      });
    }
    const regionalOffice = this.props.veteranInfo.regional_office;

    if (regionalOffice) {
      const { city, key } = regionalOffice;

      details.push({
        label: 'Regional Office',
        value: `${city} (${key.replace('RO', '')})`
      });
    }

    const getDetailField = ({ label, value }) => () => <React.Fragment>
      <span {...boldText}>{label}:</span> {value}
    </React.Fragment>;

    return <BareList ListElementComponent="ul" items={details.map(getDetailField)} />;
  };

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
    </ul>;
  };
}

const mapStateToProps = (state, ownProps) => {
  const loadingVeteranInfo = _.get(state.queue.loadingAppealDetail[ownProps.appealId], 'veteranInfo');

  return {
    veteranInfo: appealWithDetailSelector(state, { appealId: ownProps.appeal.externalId }).veteranInfo,
    loading: loadingVeteranInfo ? loadingVeteranInfo.loading : null,
    error: loadingVeteranInfo ? loadingVeteranInfo.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getAppealValue
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(VeteranDetail): React.ComponentType<Params>);

