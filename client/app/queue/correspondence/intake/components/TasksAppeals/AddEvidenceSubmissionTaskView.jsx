import React, { useEffect, useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Checkbox from '../../../../../components/Checkbox';
// import Button from '../../../../../components/Button';
import PropTypes from 'prop-types';

const AddEvidenceSubmissionTaskView = (props) => {

  // Determine if the appeal is an "evidence submission"
  const isEvidenceSubmission = props.docketName === 'evidence_submission';

  const dropdownOptions = [
    { value: 'evidence_submission', label: 'Evidence Window Submission Task', isDisabled: isEvidenceSubmission },
  ];

  const defaultValue = isEvidenceSubmission ? dropdownOptions[0] : null;
  const [isWaiveCheckboxSelected, setWaiveCheckboxSelected] = useState(false);
  const [waiveReason, setWaiveReason] = useState('');

  const handleCheckboxChange = () => {
    setWaiveCheckboxSelected(!isWaiveCheckboxSelected);

    // Clear the reason when unchecking the checkbox
    if (!isWaiveCheckboxSelected) {
      setWaiveReason('');
    }
    const canContinue = isWaiveCheckboxSelected || Boolean(waiveReason.trim());

    props.setRelatedTasksCanContinue(canContinue);
  };

  const handleReasonChange = (event) => {
    setWaiveReason(event);
    props.setRelatedTasksCanContinue(Boolean(event.trim()));
  };

  return (
    <div key={props.docketName} style={{ display: 'block', marginRight: '2rem' }}>
      <div
        className="gray-border"
        style={{
          display: 'block',
          padding: '2rem 2rem',
          marginLeft: '3rem',
          marginBottom: '3rem',
          width: '50rem'
        }}
      >
        <div
          style={{
            width: '45rem',
          }}
        >
          <div id="reactSelectContainer">
            {/* Pass the options to the ReactSelectDropdown */}
            <ReactSelectDropdown options={dropdownOptions}
              label="Task"
              defaultValue={defaultValue}
              disabled={isEvidenceSubmission} />
          </div>
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="content"
            label="Provide context and instruction on this task"
            disabled={isEvidenceSubmission}
          />
          <Checkbox
            name="waive"
            defaultValue={isWaiveCheckboxSelected}
            label="Waive Evidence Window"
            onChange={handleCheckboxChange} />
          {isWaiveCheckboxSelected && (
            <TextareaField
              name="waiveReason"
              label="Provide a reason for the waiver"
              onChange={handleReasonChange}
            />
          )}
        </div>
      </div>
    </div>
  );
};

AddEvidenceSubmissionTaskView.propTypes = {
  task: PropTypes.object.isRequired,
  docketName: PropTypes.object.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired
};

export default AddEvidenceSubmissionTaskView;
