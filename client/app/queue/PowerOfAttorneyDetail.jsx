import * as React from 'react';
import PropTypes from 'prop-types';
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
    const hasPowerOfAttorneyDetails = powerOfAttorney.representative_type && powerOfAttorney.representative_name;

    return <React.Fragment>
      { hasPowerOfAttorneyDetails &&
      <span>
        <p><strong>{powerOfAttorney.representative_type}:</strong> {powerOfAttorney.representative_name}</p>
        {powerOfAttorney.representative_address &&
          <p><strong>Address:</strong> <Address address={powerOfAttorney.representative_address} /></p>}
        {powerOfAttorney.representative_email_address &&
          <p><strong>Email Address:</strong> {powerOfAttorney.representative_email_address}</p>}
        <p><em>{COPY.CASE_DETAILS_INCORRECT_POA}</em></p>
      </span>
      }
      {!hasPowerOfAttorneyDetails && <p><em>{COPY.CASE_DETAILS_NO_POA}</em></p>}
    </React.Fragment>;
  }
}

PowerOfAttorneyDetail.propTypes = {
  appealId: PropTypes.string,
  error: PropTypes.object,
  getAppealValue: PropTypes.func,
  loading: PropTypes.bool,
  powerOfAttorney: PropTypes.shape({
    representative_type: PropTypes.string,
    representative_name: PropTypes.string,
    representative_address: PropTypes.object,
    representative_email_address: PropTypes.string
  })
};

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
