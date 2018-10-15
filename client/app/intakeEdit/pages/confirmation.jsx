import React, { Component } from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../../components/StatusMessage';

class ConfirmationPage extends Component {
  render = () => {
    const {
      veteran
    } = this.props;

    const message = `${veteran.name}'s claim review has been successfully edited. You can close this window.`;

    return <div>
      <StatusMessage
        title="Edit Confirmed"
        leadMessageList={[message]}
        type="alert" />
    </div>;
  }
}

export default connect(
  (state) => ({
    veteran: state.veteran
  })
)(ConfirmationPage);
