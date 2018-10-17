import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { removeIssue } from '../actions/addIssues';
import Modal from '../../components/Modal';

class RemoveIssueModal extends React.PureComponent {
  render() {
    return <div className="intake-remove-issue">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.closeHandler
          },
          { classNames: ['usa-button-red', 'remove-issue'],
            name: 'Yes, remove issue',
            onClick: () => {
              this.props.closeHandler();
              this.props.removeIssue(this.props.removeIndex);
            }
          }
        ]}
        visible
        closeHandler={this.props.closeHandler}
        title="Remove issue"
      >
        <p>The contention you selected will be removed from the EP in VBMS.</p>
        <p>Are you sure you want to remove this issue?</p>
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    removeIssue
  }, dispatch)
)(RemoveIssueModal);
