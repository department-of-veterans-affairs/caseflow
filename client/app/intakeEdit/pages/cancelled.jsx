import React, { Component } from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../../components/StatusMessage';

class Cancelled extends Component {
  render = () => {
    const {
      review
    } = this.props;

    const message = `${review.veteranName}'s form has been cancelled. You can close this window.`;

    return <div>
      <StatusMessage
        title="Claim Edit Cancelled"
        leadMessageList={[message]}
        type="alert" />
    </div>;
  }
}

export default connect(
  ({ review }) => ({
    review
  })
)(Cancelled);
