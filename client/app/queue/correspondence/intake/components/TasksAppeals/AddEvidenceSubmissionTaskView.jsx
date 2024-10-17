import React from 'react';
import TextareaField from '../../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Checkbox from '../../../../../components/Checkbox';
import PropTypes from 'prop-types';

const AddEvidenceSubmissionTaskView = (props) => {
  const task = props.task;

  const handleIsWaivedChange = (newIsWaved) => {
    const newTask = { id: task.id, isWaived: newIsWaved, waiveReason: task.waiveReason };

    // Parent will add/remove task from list based on isWaived
    props.taskUpdatedCallback(newTask);
  };

  const handleReasonChange = (newReason) => {
    const newTask = { id: task.id, isWaived: task.isWaived, waiveReason: newReason };

    props.taskUpdatedCallback(newTask);
  };

  const dropdownOptions = [
    { value: 'evidence_submission', label: 'Evidence Window Submission Task', isDisabled: true },
  ];

  return (
    <div key={task.id} style={{ display: 'block', marginRight: '2rem' }}>
      <div className="gray-border evidence-window-submission-box ">
        <div className="evidence-window-submission-task-dropdown">
          <div id="reactSelectContainer">
            <ReactSelectDropdown
              options={dropdownOptions}
              label="Task"
              defaultValue={dropdownOptions[0]}
              disabled
            />
          </div>
          <div className="area-below-evidence-window-submission-task-dropdown" />
          <TextareaField
            name="content"
            label="Provide context and instructions on this task"
            disabled
            textAreaStyling={{ style: { cursor: 'not-allowed' } }}
          />
          <Checkbox
            name={`${task.id}`}
            id={`${task.id}`}
            defaultValue={task.isWaived}
            label="Waive Evidence Window"
            onChange={(checked) => handleIsWaivedChange(checked)}
          />
          {task.isWaived && (
            <TextareaField
              name="waiveReason"
              label="Provide a reason for waiving the evidence window"
              onChange={handleReasonChange}
              value={task.waiveReason}
            />
          )}
        </div>
      </div>
    </div>
  );
};

AddEvidenceSubmissionTaskView.propTypes = {
  task: PropTypes.object.isRequired,
  taskUpdatedCallback: PropTypes.func.isRequired
};

export default AddEvidenceSubmissionTaskView;
