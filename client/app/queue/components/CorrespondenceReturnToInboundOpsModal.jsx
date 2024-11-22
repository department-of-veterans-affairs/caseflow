import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
// import { get } from 'lodash';

import { taskById } from '../selectors';
import { requestPatch } from '../uiReducer/uiActions';
import { taskActionData } from '../utils';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import RadioField from '../../components/RadioField';
import { RETURN_TYPES } from '../constants';
import {
  setTaskNotRelatedToAppealBanner,
  assignTaskToTeam,
  cancelTaskNotRelatedToAppeal
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceReturnToInboundOpsModal = (props) => {
  const { task_id, correspondenceInfo } = props;

  const taskList = correspondenceInfo?.tasksUnrelatedToAppeal?.find(
    (task) => parseInt(task.uniqueId, 10) === parseInt(task_id, 10)
  );

  // const organizations = taskList?.organizations || [];
  // const organizationOptions = organizations.map((org) => ({
  //   label: org.label,
  //   value: org.value
  // }));

  const taskData = taskActionData(props);

  const returnReasonOptions = [
    { displayText: RETURN_TYPES.not_appropriate,
      value: 'Not appropriate'},
    { displayText: RETURN_TYPES.clarification_needed,
      value: 'Clarification needed'},
    { displayText: RETURN_TYPES.other,
      value: 'Other'}
  ];

  const [reasonSelected, setReasonSelected] = useState(null);

  const [otherReason, setOtherReason] = useState('');


  const handleSetOtherReasonChange = (value) => setOtherReason(value)
  const handleSetReasonSelectedChange = (value) => setReasonSelected(value)


  const validateForm = () => {
    if (reasonSelected === "Other") {
      return (otherReason.length > 0)
    }
    if (reasonSelected !== null) {
      return true
    }

    return false;
  };

  // Could possibly use updateCorrespondence method from client/app/queue/components/CorrespondenceAssignTeamModal.jsx

  const submit = () => {
    // Could possibly use submit method from client/app/queue/components/CorrespondenceAssignTeamModal.jsx
    console.log(reasonSelected);
  };

  const modalProps = {
    submitButtonClassNames: ['usa-button'],
    submitDisabled: !validateForm()
  };

  return (
    <QueueFlowModal
      {...modalProps}
      title={COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_TITLE}
      button="Return"
      pathAfterSubmit={taskData?.redirect_after ?? `/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
      validateForm={validateForm}
    >
      <RadioField
        id="returnReasonRadioField"
        name={COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_SUBTITLE}
        // required
        options={returnReasonOptions}
        // value={returnReasonOptions[1]}
        // errorMessage={"Error"}
        onChange={handleSetReasonSelectedChange}
      />
      { reasonSelected === "Other" && (
        <TextareaField
          name={taskData?.instructions_label ?? COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_OTHER_REASON_TITLE}
          id="otherReturnReason"
          onChange={handleSetOtherReasonChange}
          value={otherReason}
        />
      )}
    </QueueFlowModal>
  );
};
/* eslint-enable camelcase */

CorrespondenceReturnToInboundOpsModal.propTypes = {
  requestPatch: PropTypes.func,
  task: PropTypes.shape({
    assignedTo: PropTypes.shape({
      type: PropTypes.string
    }),
    taskId: PropTypes.string,
    type: PropTypes.string
  }),
  task_id: PropTypes.string,
  correspondence_uuid: PropTypes.string,
  correspondenceInfo: PropTypes.shape({
    tasksUnrelatedToAppeal: PropTypes.arrayOf(PropTypes.shape({
      uniqueId: PropTypes.number,
      organizations: PropTypes.arrayOf(PropTypes.shape({
        label: PropTypes.string,
        value: PropTypes.number
      }))
    }))
  })
};

const mapStateToProps = (state, ownProps) => ({
  task: taskById(state, { taskId: ownProps.task_id }),
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestPatch,
  setTaskNotRelatedToAppealBanner,
  cancelTaskNotRelatedToAppeal,
  assignTaskToTeam
}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceReturnToInboundOpsModal)
);
