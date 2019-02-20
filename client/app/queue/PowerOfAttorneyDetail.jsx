import * as React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import COPY from '../../COPY.json';
import { getAppealValue } from './QueueActions';
import { appealWithDetailSelector } from './selectors';
import Address from './components/Address';

export class PowerOfAttorneyDetail extends React.PureComponent {
  componentDidMount = () => {
    if (!this.props.powerOfAttorney) {
      this.props.getAppealValue(
        this.props.appealId,
        'power_of_attorney',
        'powerOfAttorney'
      );
    }
  }

  render = () => {
    const {
      loading,
      error,
      powerOfAttorney
    } = this.props;

    if (!powerOfAttorney) {
      if (loading) {
        return <React.Fragment>{COPY.CASE_DETAILS_LOADING}</React.Fragment>;
      }
      if (error) {
        return <React.Fragment>
          {COPY.CASE_DETAILS_UNABLE_TO_LOAD}
        </React.Fragment>;
      }

      return null;
    }

    return <React.Fragment>
      <p><strong>{powerOfAttorney.representative_type}:</strong> {powerOfAttorney.representative_name}</p>
      {powerOfAttorney.representative_address &&
        <p><strong>Address:</strong> <Address address={powerOfAttorney.representative_address} /></p>}
      <p><em>{COPY.CASE_DETAILS_INCORRECT_POA}</em></p>
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const loadingPowerOfAttorney = _.get(state.queue.loadingAppealDetail[ownProps.appealId], 'powerOfAttorney');

  return {
    powerOfAttorney: appealWithDetailSelector(state, { appealId: ownProps.appealId }).powerOfAttorney,
    loading: loadingPowerOfAttorney ? loadingPowerOfAttorney.loading : null,
    error: loadingPowerOfAttorney ? loadingPowerOfAttorney.error : null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getAppealValue
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(PowerOfAttorneyDetail));
