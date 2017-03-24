import React, { PropTypes } from 'react';
import ProgressBar from '../../components/ProgressBar';

export default class EstablishClaimProgressBar extends React.Component {

  render() {
    return <ProgressBar
      sections = {
      [
        {
          current: this.props.isReviewDecision,
          title: '1. Review Decision'
        },
        {
          current: this.props.isRouteClaim,
          title: '2. Route Claim'
        },
        {
          current: this.props.isConfirmation,
          title: '3. Confirmation'
        }
      ]
      }
    />;
  }
}

EstablishClaimProgressBar.propTypes = {
  isConfirmation: PropTypes.bool,
  isReviewDecision: PropTypes.bool,
  isRouteClaim: PropTypes.bool
};
