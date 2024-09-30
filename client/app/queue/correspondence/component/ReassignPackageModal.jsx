import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ApiUtil from '../../../util/ApiUtil';
import { sprintf } from 'sprintf-js';
import { useSelector } from 'react-redux';
import TextareaField from '../../../components/TextareaField';
import ReactSelectDropdown from '../../../components/ReactSelectDropdown';
import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';
import RadioFieldWithChildren from '../../../components/RadioFieldWithChildren';

const ReassignPackageModal = (props) => {
  const [selectedRequestChoice, setSelectedRequestChoice] = useState('');
  const [selectedMailTeamUser, setSelectedMailTeamUser] = useState('');
  const [decisionReason, setDecisionReason] = useState('');
  const taskInstructions = useSelector((state) => state.reviewPackage.taskInstructions);

  const { onCancel } = props;
  const submit = () => {
    try {
      const data = {
        action_type: 'reassign',
        new_assignee: selectedMailTeamUser,
        decision: selectedRequestChoice,
        decision_reason: decisionReason,
      };

      ApiUtil.patch(`/queue/correspondence/tasks/${props.blockingTaskId}/update`, { data }).
        then(() => {
          window.location.href = '/queue/correspondence/team';
        });

    } catch (error) {
      console.error(error);
    }
  };

  const confirmButtonDisabled = () => {
    if (selectedRequestChoice === 'approve' && selectedMailTeamUser === '') {
      return true;
    }

    if (selectedRequestChoice === 'reject' && decisionReason === '') {
      return true;
    }

    if (selectedRequestChoice === '') {
      return true;
    }

    return false;
  };

  const buildMailUserData = (data) => {

    if (typeof data === 'undefined') {
      return [];
    }

    return data.map((user) => {
      return {
        value: user,
        label: user
      };
    });
  };

  const approveElement = (
    <div style={{ width: '16vw' }}>
      <ReactSelectDropdown
        className="cf-margin-left-2rem img"
        label="Assign to person"
        onChangeMethod={(val) => setSelectedMailTeamUser(val.value)}
        options={buildMailUserData(props.inboundOpsTeamUsers)}
      />
    </div>
  );

  const textAreaElement = (
    <div style={{ width: '100%' }}>
      <TextareaField label="Provide a reason for rejection"
        onChange={setDecisionReason}
        name="reason-text-area"
        value={decisionReason} />
    </div>
  );

  const reassignOptions = [
    { displayText: 'Approve request',
      value: 'approve',
      element: approveElement,
      displayElement: selectedRequestChoice === 'approve'
    },
    { displayText: 'Reject request',
      value: 'reject',
      element: textAreaElement,
      displayElement: selectedRequestChoice === 'reject'
    }
  ];

  return (
    <Modal
      title= {sprintf(COPY.CORRESPONDENCE_HEADER_REMOVE_PACKAGE)}
      closeHandler={onCancel}
      confirmButton={<Button disabled={(confirmButtonDisabled())}
        onClick={() => (submit())}>Confirm</Button>}
      cancelButton={<Button linkStyling onClick={onCancel}>Cancel</Button>}
    >
      <p>
        <span style= {{ fontWeight: 'bold' }}>{sprintf(COPY.CORRESPONDENCE_TITLE_REASSIGN_PACKAGE)}</span><br />
        {taskInstructions[0]}
      </p>

      <RadioFieldWithChildren
        vertical
        label={sprintf(COPY.CORRRESPONDENCE_LABEL_OPTION_REASSIGN_PACKAGE)}
        name="reassign-package"
        value={selectedRequestChoice}
        options={reassignOptions}
        onChange={(val) => setSelectedRequestChoice(val)}
      />
    </Modal>
  );
};

ReassignPackageModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  inboundOpsTeamUsers: PropTypes.array,
  setModalState: PropTypes.func,
  correspondence_id: PropTypes.number,
  taskInstructions: PropTypes.array,
  blockingTaskId: PropTypes.number,
  updateLastAction: PropTypes.func,
};

export default ReassignPackageModal;
