import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';
import ApiUtil from 'app/util/ApiUtil';
import { useDispatch, useSelector } from 'react-redux';
import { setUnrelatedTaskList } from '../../../correspondenceDetailsReducer/correspondenceDetailsActions';

const AddTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  correspondence,
  task,
  displayRemoveCheck,
  removeTask,
}) => {
  const dispatch = useDispatch();

  // Redux state for unrelatedTaskList
  const unrelatedTaskList = useSelector((state) => state.correspondenceDetails.unrelatedTaskList);

  const [taskTypeOptions, setTaskTypeOptions] = useState([]);
  // State to track the task content
  const [taskContent, setTaskContent] = useState('');
  // State to track the selected task type
  const [selectedTaskType, setSelectedTaskType] = useState(null);
  // State to track if the Next button should be disabled
  const [isNextDisabled, setIsNextDisabled] = useState(true);

  // Function to filter out the task options based on the unrelatedTaskList, ensuring case-insensitive comparison
  const getFilteredTaskTypeOptions = () => {
    return INTAKE_FORM_TASK_TYPES.unrelatedToAppeal.
      filter((option) =>
        !unrelatedTaskList.some(
          // Exclude already added tasks with case-insensitive comparison
          (existingTask) => existingTask.label.toLowerCase() === option.label.toLowerCase()
        )
      ).
      map((option) => ({
        value: option.value,
        label: option.label,
      }));
  };

  // Recalculate task options every time the component loads or unrelatedTaskList changes
  useEffect(() => {
    setTaskTypeOptions(getFilteredTaskTypeOptions());
  }, [unrelatedTaskList]);

  // Check if the Next button should be disabled or enabled
  useEffect(() => {
    setIsNextDisabled(!(selectedTaskType && taskContent));
  }, [selectedTaskType, taskContent]);

  // Function to update task type based on user selection
  const updateTaskType = (newType) => {
    // Set the selected task type (klass, assigned_to)
    setSelectedTaskType(newType.value);
  };

  // Function to update task content when user types in the TextareaField
  const updateTaskContent = (newContent) => {
    // Update task content state
    setTaskContent(newContent);

  };

  // Function to handle the "Next" button click
  const handleNext = async () => {
    if (selectedTaskType && taskContent) {
      const newTask = {
        klass: selectedTaskType.klass,
        assigned_to: selectedTaskType.assigned_to,
        content: taskContent,
        // Store label for new task
        label: taskTypeOptions.find((option) => option.value === selectedTaskType)?.label,
        // Add current date as assignedOn
        assignedOn: new Date().toISOString(),
        // Map taskContent to instructions array
        instructions: [taskContent],
      };

      const patchData = {
        tasks_not_related_to_appeal: [newTask],
      };

      try {
        await ApiUtil.patch(
          `/queue/correspondence/${correspondence.uuid}/update_correspondence`,
          { data: patchData }
        );

        // Dispatch action to append the new task to unrelatedTaskList in Redux
        dispatch(setUnrelatedTaskList([...unrelatedTaskList, newTask]));

        setTaskContent('');

        // Close the modal after the task is successfully added
        handleClose();
      } catch (error) {
        console.error('Error adding task:', error);
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
        // Call the handleNext function when clicking Next
          onClick={handleNext}
          // Disable the Next button until both fields are filled
          disabled={isNextDisabled}
        >
          Next
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
            // Filtered task options
            options={taskTypeOptions}
            onChange={updateTaskType}
            className="add-task-dropdown-style"
            aria-label="dropdown"
          />
        </div>

        <TextareaField
          name="content"
          label="Provide context and instruction on this task"
          // Bind the TextareaField to taskContent state
          value={taskContent}
          // Call updateTaskContent when content changes
          onChange={updateTaskContent}
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
  displayRemoveCheck: PropTypes.bool.isRequired,
  removeTask: PropTypes.func.isRequired,
};

export default AddTaskModalCorrespondenceDetails;
