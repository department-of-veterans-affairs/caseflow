import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import {
  resetErrorMessages,
  resetSuccessMessages
} from '../uiReducer/uiActions';
import { requestDistribution } from '../QueueActions';
import Button from '../../components/Button';

class RequestDistributionButton extends React.PureComponent {
  requestDistributionSubmit = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
    // Note: the default value of "" will never be used, and will fail on the backend.
    // Even though this code path will never be hit unless we have a value for userId,
    // Flow complains without a default value.
    this.props.requestDistribution(this.props.userId || '');
  }

  render = () => {
    return <React.Fragment>
      <div {...css({ marginLeft: 'auto' })}>
        <Button
          name="Request more cases"
          onClick={this.requestDistributionSubmit}
          loading={this.props.distributionLoading}
          classNames={['usa-button-secondary', 'cf-push-right']} />
      </div>
    </React.Fragment>;
  }
}

RequestDistributionButton.propTypes = {
  userId: PropTypes.number.isRequired,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  requestDistribution: PropTypes.func,
  distributionLoading: PropTypes.bool
};

const mapStateToProps = (state) => {
  const { pendingDistribution } = state.queue;

  return {
    distributionLoading: pendingDistribution !== null
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  resetErrorMessages,
  resetSuccessMessages,
  requestDistribution
}, dispatch);

export default (connect(
  mapStateToProps,
  mapDispatchToProps
)(RequestDistributionButton));
