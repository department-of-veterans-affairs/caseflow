import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import { removeIssue } from '../actions/addIssues';
import Modal from '../../components/Modal';
import { benefitTypeProcessedInVBMS } from '../util';

const removeIssueMessage = (intakeData) => {
  if (intakeData.benefitType && !benefitTypeProcessedInVBMS(intakeData.benefitType)) {
    return <div>
      <p>The contention you selected will be removed from the decision review.</p>
      <p>Are you sure you want to remove this issue?</p>
    </div>;
  }

  if (intakeData.formType === 'appeal') {
    return <div>
      <p>The issue you selected will be removed from the list of issues on appeal.</p>
      <p>Are you sure that this issue is not listed on the veteran's NOD and that you want to remove it?</p> </div>;
  }

  return <div>
    <p>The contention you selected will be removed from the EP in VBMS.</p>
    <p>Are you sure you want to remove this issue?</p> </div>;

};

class RemoveIssueModal extends React.PureComponent {
  render() {
    const {
      intakeData,
      removeIndex
    } = this.props;

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
              this.props.removeIssue(removeIndex);
            }
          }
        ]}
        visible
        closeHandler={this.props.closeHandler}
        title="Remove issue"
      >

        { removeIssueMessage(intakeData) }

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
