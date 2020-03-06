import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import COPY from '../../COPY';
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

  hasPowerOfAttorneyDetails() {
    const { powerOfAttorney } = this.props;

    return powerOfAttorney.representative_type && powerOfAttorney.representative_name;
  }

  renderNameOnly() {
    if (this.hasPowerOfAttorneyDetails) {
      const { powerOfAttorney } = this.props;

      return <span>{powerOfAttorney.representative_name}</span>;
    }

    return <span>{COPY.CASE_DETAILS_NO_POA}</span>;

  }

  renderLoadingOrError() {
    const { loading, error } = this.props;

    if (loading) {
      return <React.Fragment>{COPY.CASE_DETAILS_LOADING}</React.Fragment>;
    }

    if (error) {
      return <React.Fragment>{COPY.CASE_DETAILS_UNABLE_TO_LOAD}</React.Fragment>;
    }

    return null;
  }

  render = () => {
    const { displayNameOnly, powerOfAttorney } = this.props;

    if (!powerOfAttorney) {
      return this.renderLoadingOrError();
    }

    if (displayNameOnly) {
      return this.renderNameOnly();
    }

    if (!this.hasPowerOfAttorneyDetails()) {
      return <p><em>{COPY.CASE_DETAILS_NO_POA}</em></p>;
    }

    return (
      <React.Fragment>
        <span>
          <p>
            <strong>{powerOfAttorney.representative_type}:</strong> {powerOfAttorney.representative_name}
          </p>
          {powerOfAttorney.representative_address &&
              <p><strong>Address:</strong> <Address address={powerOfAttorney.representative_address} /></p>}
          {powerOfAttorney.representative_email_address &&
              <p><strong>Email Address:</strong> {powerOfAttorney.representative_email_address}</p>}
          <p><em>{COPY.CASE_DETAILS_INCORRECT_POA}</em></p>
        </span>
      </React.Fragment>
    );

  }
}

PowerOfAttorneyDetail.propTypes = {
  appealId: PropTypes.string,
  error: PropTypes.object,
  getAppealValue: PropTypes.func,
  loading: PropTypes.bool,
  displayNameOnly: PropTypes.bool,
  powerOfAttorney: PropTypes.shape({
    representative_type: PropTypes.string,
    representative_name: PropTypes.string,
    representative_address: PropTypes.object,
    representative_email_address: PropTypes.string
  })
};

PowerOfAttorneyDetail.defaultProps = {
  displayNameOnly: false
};

const mapStateToProps = (state, ownProps) => {
  const loadingPowerOfAttorney = _.get(state.queue.loadingAppealDetail[ownProps.appealId], 'powerOfAttorney');

  if (_.isUndefined(loadingPowerOfAttorney) || loadingPowerOfAttorney.loading) {
    return { loading: true };
  }

  const appeal = appealWithDetailSelector(state, { appealId: ownProps.appealId });

  if (!appeal) {
    return { loading: true };
  }

  return {
    powerOfAttorney: appeal.powerOfAttorney,
    loading: null,
    error: loadingPowerOfAttorney.error
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  getAppealValue
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(PowerOfAttorneyDetail);
