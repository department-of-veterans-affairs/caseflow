import React from 'react';
import PropTypes from 'prop-types';
import QueueFlowModal from '../components/QueueFlowModal';
import COPY from '../../../COPY';

export const CavcDashboardDetailsModal = ({ onCancel }) => {
  const validateForm = () => {
    return this.state.modal.assignedUser !== null &&
      this.state.modal.taskType !== null &&
      this.state.modal.numberOfTasks !== null;
  };

  return (
    <QueueFlowModal
      pathAfterSubmit={`/queue/appeals/${remand.remand_appeal_uuid}/cavc_dashboard`}
      button={COPY.MODAL_SAVE_BUTTON}
      onCancel={onCancel}
      submit={this.bulkAssignTasks}
      validateForm={validateForm}
      title={COPY.CAVC_DASHBOARD_EDIT_DETAILS_MODAL_TITLE}>
      <p>This is a test</p>
    </QueueFlowModal>
  );
};

CavcDashboardDetailsModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
