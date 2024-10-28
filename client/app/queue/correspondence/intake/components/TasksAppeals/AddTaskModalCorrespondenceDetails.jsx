import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
import Checkbox from '../../../../../components/Checkbox';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';
import { useDispatch, useSelector } from 'react-redux';
import { addTaskNotRelatedToAppeal } from '../../../correspondenceDetailsReducer/correspondenceDetailsActions';
import { maxWidthFormInput } from '../../../../../hearings/components/details/style';

const AddTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  correspondence,
  task,
  displayRemoveCheck,
  removeTask,
  setIsTasksUnrelatedSectionExpanded,
  autoTexts
}) => {
  const dispatch = useDispatch();

  // Redux state for unrelatedTaskList
  // eslint-disable-next-line max-len
  const unrelatedTaskList = useSelector((state) => state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal);
  // Track current page
  const [isSecondPage, setIsSecondPage] = useState(false);
  const [taskTypeOptions, setTaskTypeOptions] = useState([]);
  // Combined task content from both pages
  const [taskContent, setTaskContent] = useState('');
  // Second page content
  const [additionalContent, setAdditionalContent] = useState('');
  const [selectedTaskType, setSelectedTaskType] = useState(null);
  // Controls Submit button state
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  // Tracks selected checkboxes on the second page
  const [autoTextSelections, setAutoTextSelections] = useState([]);

  // Generic auto-text options for second page checkboxes
  const checkboxData = autoTexts;

  // Task type options filtered by unrelated tasks
  const getFilteredTaskTypeOptions = () => {
    return INTAKE_FORM_TASK_TYPES.unrelatedToAppeal.
      // eslint-disable-next-line max-len
      filter((option) => !unrelatedTaskList.some((existingTask) => existingTask.label.toLowerCase() === option.label.toLowerCase())).
      map((option) => ({ value: option.value, label: option.label }));
  };

  useEffect(() => {
    setTaskTypeOptions(getFilteredTaskTypeOptions());
  }, [unrelatedTaskList]);

  // Update submit button enabled state based on input availability
  useEffect(() => {
    setIsSubmitDisabled(!(taskContent || additionalContent) || !selectedTaskType || isLoading);
  }, [taskContent, additionalContent, selectedTaskType, isLoading]);

  // Handle task type selection
  const updateTaskType = (newType) => setSelectedTaskType(newType.value);

  // Update task content (first page text area)
  const updateTaskContent = (newContent) => setTaskContent(newContent);

  // Update additional content (second page text area)
  const updateAdditionalContent = (newContent) => setAdditionalContent(newContent);

  // Toggle checkboxes for auto-text selections and append checked text to additional content
  const handleToggleCheckbox = (checkboxText) => {
    setAutoTextSelections((prevSelections) => {
      const newSelections = prevSelections.includes(checkboxText) ?
        prevSelections.filter((item) => item !== checkboxText) :
        [...prevSelections, checkboxText];

      // Update additional content with selected texts
      setAdditionalContent(newSelections.join('\n'));

      return newSelections;
    });

  };

  // Handle the "Next" button click to navigate to the second page
  const handleNext = () => setIsSecondPage(true);

  // Handle Submit functionality on the second page
  const handleSubmit = async () => {
    const combinedContent = taskContent ? `${taskContent}\n${additionalContent}` : additionalContent;

    const newTask = {
      klass: selectedTaskType.klass,
      assigned_to: selectedTaskType.assigned_to,
      content: combinedContent,
      label: taskTypeOptions.find((option) => option.value === selectedTaskType)?.label,
      assignedOn: new Date().toISOString(),
      instructions: [combinedContent],
    };

    setIsLoading(true);

    try {
      // Dispatch action to add task and wait for completion
      await dispatch(addTaskNotRelatedToAppeal(correspondence, newTask));
      // Reset content fields
      setTaskContent('');
      setAdditionalContent('');
      setSelectedTaskType(null);
      setIsTasksUnrelatedSectionExpanded(true);
      setIsSecondPage(false);
      setAutoTextSelections([]);
      handleClose();
    } catch (error) {
      console.error('Error while adding task:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Navigate back to the first page
  const handleBack = () => setIsSecondPage(false);

  if (!isOpen) {
    return null;
  }

  return (
    <Modal
      title="Add task to correspondence"
      closeHandler={handleClose}
      confirmButton={
        <Button
          // "Submit" on second page, "Next" on first
          onClick={isSecondPage ? handleSubmit : handleNext}
          // "Next" always enabled, "Submit" conditionally
          disabled={isSecondPage ? isSubmitDisabled : false}
        >
          {isLoading ? 'Loading...' : isSecondPage ? 'Submit' : 'Next'}
        </Button>
      }
      cancelButton={
        <Button linkStyling onClick={handleClose} disabled={isLoading}>
          Cancel
        </Button>
      }
    >
      {isSecondPage ? (
        // Second page content with Checkbox selections and additional TextareaField
        <div className="add-task-modal-container">
          <div className="checkbox-modal-size">
            {checkboxData.map((checkboxText) => (
              <Checkbox
                key={checkboxText}
                name={checkboxText}
                onChange={() => handleToggleCheckbox(checkboxText)}
                value={autoTextSelections.includes(checkboxText)}

              />
            ))}
          </div>
          <TextareaField
            name="additionalContent"
            label="Additional Instructions"
            value={additionalContent}
            onChange={updateAdditionalContent}
            classNames={['task-selection-dropdown-box']}
            styling={maxWidthFormInput}
          />
          <Button onClick={handleBack}>Back</Button>
        </div>
      ) : (
        // First page content with task selection and main TextareaField
        <div className="add-task-modal-container">
          <div className="task-selection-dropdown-box">
            <label className="task-selection-title">Task</label>
            <Select
              placeholder="Select..."
              options={taskTypeOptions}
              classNamePrefix="react-select"
              className="add-task-dropdown-style"
              onChange={updateTaskType}
              value={taskTypeOptions.find((taskOption) => taskOption.value === selectedTaskType)}
            />
          </div>

          <TextareaField
            name="content"
            label="Provide context and instructions on this task"
            value={taskContent}
            onChange={updateTaskContent}
            classNames={['task-selection-dropdown-box']}
            styling={maxWidthFormInput}
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
      )}
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
  setIsTasksUnrelatedSectionExpanded: PropTypes.func.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddTaskModalCorrespondenceDetails;
