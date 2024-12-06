import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import RadioField from '../../components/RadioField';
import { RETURN_TYPES } from '../constants';
import {
  returnTaskToInboundOps
} from '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

/* eslint-disable camelcase */
const CorrespondenceReturnToInboundOpsModal = (props) => {
  const returnReasonOptions = [
    { displayText: RETURN_TYPES.not_appropriate,
      value: RETURN_TYPES.not_appropriate },
    { displayText: RETURN_TYPES.clarification_needed,
      value: RETURN_TYPES.clarification_needed },
    { displayText: RETURN_TYPES.other,
      value: RETURN_TYPES.other }
  ];

  const [reasonSelected, setReasonSelected] = useState(RETURN_TYPES.not_appropriate);

  const [otherReason, setOtherReason] = useState('');

  const handleSetOtherReasonChange = (value) => setOtherReason(value);
  const handleSetReasonSelectedChange = (value) => setReasonSelected(value);

  const validateForm = () => {
    if (reasonSelected === RETURN_TYPES.other) {
      return (otherReason.length > 0);
    }
    if (reasonSelected !== null) {
      return true;
    }

    return false;
  };

  const submit = () => {
    const updatedTask = props.correspondenceInfo.tasksUnrelatedToAppeal.find(
      (task) => parseInt(props.task_id, 10) === parseInt(task.uniqueId, 10)
    );

    const payload = {
      data: { return_reason: reasonSelected === RETURN_TYPES.other ? otherReason : reasonSelected }
    };

    const frontendParams = {
      taskId: props.task_id,
      taskName: updatedTask.label,
      assignedName: updatedTask.assignedTo
    };

    return props.returnTaskToInboundOps(payload, frontendParams, props.correspondenceInfo);
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
      pathAfterSubmit={`/queue/correspondence/${props.correspondence_uuid}`}
      submit={submit}
      validateForm={validateForm}
    >
      <RadioField
        id="returnReasonRadioField"
        className={['return-to-iot-radio-field']}
        name={COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_SUBTITLE}
        options={returnReasonOptions}
        value={reasonSelected}
        onChange={handleSetReasonSelectedChange}
      />
      { reasonSelected === RETURN_TYPES.other && (
        <TextareaField
          name={COPY.CORRESPONDENCE_RETURN_TO_INBOUND_OPS_MODAL_OTHER_REASON_TITLE}
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
  returnTaskToInboundOps: PropTypes.func,
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
      organizations: PropTypes.arrayOf(PropTypes.shape({
        value: PropTypes.number,
        label: PropTypes.string
      })),
      uniqueId: PropTypes.number
    }))
  })
};

const mapStateToProps = (state) => ({
  taskNotRelatedToAppealBanner: state.correspondenceDetails.bannerAlert,
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  showActionsDropdown: state.correspondenceDetails.showActionsDropdown,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  returnTaskToInboundOps
}, dispatch);

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceReturnToInboundOpsModal)
);
