import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';
import ApiUtil from 'app/util/ApiUtil';

const AddTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  correspondence,
  task,
  // taskUpdatedCallback,
  displayRemoveCheck,
  removeTask,
}) => {
  const [taskTypeOptions, setTaskTypeOptions] = useState([]);
  const [taskContent, setTaskContent] = useState(''); // State to track the task content
  const [selectedTaskType, setSelectedTaskType] = useState(null); // State to track the selected task type

  // Extract the labels from INTAKE_FORM_TASK_TYPES.unrelatedToAppeal for use in Select component
  useEffect(() => {
    const allTaskTypeOptions = INTAKE_FORM_TASK_TYPES.unrelatedToAppeal.map((option) => ({
      value: option.value,
      label: option.label,
    }));
    setTaskTypeOptions(allTaskTypeOptions);
  }, []);

  // Function to update task type based on user selection
  const updateTaskType = (newType) => {
    setSelectedTaskType(newType.value); // Set the selected task type (klass, assigned_to)
  };

  // Function to update task content when user types in the TextareaField
  const updateTaskContent = (newContent) => {
    setTaskContent(newContent); // Update task content state
  };

  // Function to handle the "Confirm" button click
  const handleConfirm = async () => {
    if (selectedTaskType && taskContent) {
      const patchData = {
        tasks_not_related_to_appeal: [
          {
            klass: selectedTaskType.klass,
            assigned_to: selectedTaskType.assigned_to,
            content: taskContent,
          },
        ],
      };

      // Send the API request with the task data
      try {
        console.log(patchData);
        await ApiUtil.patch(
          `/queue/correspondence/${correspondence.uuid}/update_correspondence`, // Use correspondence.uuid here
          { data: patchData }
        );
        // If successful, call onSubmit and close the modal
        handleClose();
      } catch (error) {
        // Handle error
        console.error(error);
      }
    }
  };

  if (!isOpen) {
    return null;
  }

  return (
    <Modal
      title="Add New Task"
      closeHandler={handleClose}
      confirmButton={
        <Button
          onClick={handleConfirm} // Call the handleConfirm function when clicking Confirm
        >
          Confirm
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={handleClose}>
          Cancel
        </Button>
      }
    >
      <div className="add-task-modal-container">
        <div className="task-selection-dropdown-box">
          <label className="task-selection-title">Task</label>
          <Select
            placeholder="Select..."
            options={taskTypeOptions}
            onChange={updateTaskType}
            className="add-task-dropdown-style"
            aria-label="dropdown"
          />
        </div>

        <TextareaField
          name="content"
          label="Provide context and instruction on this task"
          value={taskContent} // Bind the TextareaField to taskContent state
          onChange={updateTaskContent} // Call updateTaskContent when content changes
        />

        {displayRemoveCheck && (
          <Button
            name="Remove"
            onClick={() => removeTask(task.id)}
            classNames={['cf-btn-link', 'cf-right-side', 'remove-task-button']}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
          </Button>
        )}
      </div>
    </Modal>
  );
};

AddTaskModalCorrespondenceDetails.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  handleClose: PropTypes.func.isRequired,
  correspondence: PropTypes.object.isRequired,
  onSubmit: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  taskUpdatedCallback: PropTypes.func.isRequired,
  displayRemoveCheck: PropTypes.bool.isRequired,
  removeTask: PropTypes.func.isRequired,
};

export default AddTaskModalCorrespondenceDetails;
