import React, { PropTypes } from 'react';
import ProgressBar from '../../components/ProgressBar';

export default class EstablishClaimProgressBar extends React.Component {

  render() {
    return <ProgressBar
      sections = {
      [
        {
          activated: this.props.isReviewDecision,
          title: '1. Review Decision'
        },
        {
          activated: this.props.isRouteClaim,
          title: '2. Route Claim'
        },
        {
          activated: this.props.isConfirmation,
          title: '3. Confirmation'
        }
      ]
      }
    />;
  }
}

EstablishClaimProgressBar.propTypes = {
  isConfirmation: PropTypes.bool.isRequired,
  isReviewDecision: PropTypes.bool.isRequired,
  isRouteClaim: PropTypes.bool.isRequired
};
