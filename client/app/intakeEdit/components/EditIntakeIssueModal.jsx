import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import {
  INTAKE_EDIT_ISSUE_TITLE,
  INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES,
  INTAKE_EDIT_ISSUE_CHANGE_MESSAGE,
  INTAKE_EDIT_ISSUE_LABEL,
  INTAKE_EDIT_ISSUE_BENEFIT_TYPE,
  INTAKE_EDIT_ISSUE_DECISION_DATE,
} from 'app/../COPY';

export class EditIntakeIssueModal extends React.Component {

  handleMstStatus(mst_status) {
    this.setState({ mst_status });
  }

  handlePactStatus(pact_status) {
    this.setState({ pact_status });
  }

  render() {
    const {
      issueIndex,
      intakeData,
      mst_status,
      pact_status,
      onCancel
    } = this.props;

    return <div className="edit-intake-issue">
      {console.log(`props print here: ${JSON.stringify(intakeData, null, '\t')}`)}
      {console.log(`wut is this: ${JSON.stringify(issueIndex)}`)}
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.onCancel
          },
          { classNames: ['usa-button-blue', 'save-issue'],
            name: 'Save issue',
            onClick: () => {
              this.props.onSubmit();
            //  this.props.mstUpdate(mst_status);
            //  this.props.pactUpdate(pact_status);
            }
          }
        ]}
        visible
        closeHandler={onCancel}
        title={INTAKE_EDIT_ISSUE_TITLE}
      >
        { INTAKE_EDIT_ISSUE_LABEL} {this.props.intakeData.addedIssues[issueIndex].category + " - " + this.props.intakeData.addedIssues[issueIndex].description}
        { INTAKE_EDIT_ISSUE_BENEFIT_TYPE }
        { INTAKE_EDIT_ISSUE_DECISION_DATE }
        { INTAKE_EDIT_ISSUE_SELECT_SPECIAL_ISSUES }
        // Checkboxes
      </Modal>
    </div>;
  }
}

EditIntakeIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  issueIndex: PropTypes.number,
};

export default EditIntakeIssueModal;
