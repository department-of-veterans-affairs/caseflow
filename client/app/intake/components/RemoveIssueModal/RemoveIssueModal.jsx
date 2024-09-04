import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';
import PropTypes from 'prop-types';

import { removeIssue } from '../../actions/addIssues';
import { updatePendingReview } from 'app/intake/actions/issueModificationRequest';
import Modal from '../../../components/Modal';
import { benefitTypeProcessedInVBMS } from '../../util';
import { isEmpty } from 'lodash';
import COPY from 'app/../COPY';

const removeIssueMessage = (intakeData) => {
  if (intakeData.benefitType && !benefitTypeProcessedInVBMS(intakeData.benefitType)) {
    return <div>
      <p>The contention you selected will be removed from the decision review.</p>
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
      removeIndex,
      userIsVhaAdmin
    } = this.props;

    const onSubmit = () => {
      const activeIssueModificationRequest = intakeData.activeIssueModificationRequest;
      let removePendingIndex;

      if (userIsVhaAdmin && !isEmpty(activeIssueModificationRequest)) {
        removePendingIndex = intakeData.addedIssues.
          findIndex((issue) => issue?.id === activeIssueModificationRequest.requestIssue?.id);

        this.props.updatePendingReview(activeIssueModificationRequest.identifier, activeIssueModificationRequest);
      } else {
        removePendingIndex = removeIndex;
      }
      this.props.removeIssue(removePendingIndex);
    };

    return <div className="intake-remove-issue">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.closeHandler
          },
          { classNames: ['usa-button', 'remove-issue'],
            name: COPY.MODAL_REMOVE_BUTTON,
            onClick: () => {
              this.props.closeHandler();
              onSubmit();
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

RemoveIssueModal.propTypes = {
  closeHandler: PropTypes.func.isRequired,
  intakeData: PropTypes.object.isRequired,
  removeIndex: PropTypes.number.isRequired,
  removeIssue: PropTypes.func.isRequired,
  updatePendingReview: PropTypes.func.isRequired,
  pendingIssueModificationRequest: PropTypes.object,
  userIsVhaAdmin: PropTypes.bool
};

export default connect(
  null,
  (dispatch) => bindActionCreators({
    removeIssue,
    updatePendingReview
  }, dispatch)
)(RemoveIssueModal);
