import React, { Component } from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../../components/StatusMessage';

class Canceled extends Component {
  render = () => {
    const {
      veteran
    } = this.props;

    const message = `${veteran.name}'s form has been cancelled. You can close this window.`;

    return <div>
      <StatusMessage
        title="Claim Edit Canceled"
        leadMessageList={[message]}
        type="alert" />
    </div>;
  }
}

export default connect(
  (state) => ({
    veteran: state.veteran
  })
)(Canceled);
