import React, { Component } from 'react';
import { connect } from 'react-redux';
import StatusMessage from '../../components/StatusMessage';

class ClaimNotEditable extends Component {
  render = () => {
    const {
      veteran
    } = this.props;

    const message = `Because this claim was created by Caseflow to resolve DTA errors, it's issues may not be edited. You can close this window and return to VBMS.`;

    return <div>
      <StatusMessage
        title="Issues Not Editable"
        leadMessageList={[message]} />
    </div>;
  }
}

export default connect(
  (state) => ({
    veteran: state.veteran
  })
)(ClaimNotEditable);
