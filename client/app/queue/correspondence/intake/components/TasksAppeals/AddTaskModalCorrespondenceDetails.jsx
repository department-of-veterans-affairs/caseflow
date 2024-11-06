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
import { maxWidthFormInput, ninetySixWidthFormInput } from '../../../../../hearings/components/details/style';

const AddTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  correspondence,
  setIsTasksUnrelatedSectionExpanded,
  autoTexts
}) => {
  const dispatch = useDispatch();

  // Redux state for unrelatedTaskList, needed to filter task options
  // eslint-disable-next-line max-len
  const unrelatedTaskList = useSelector((state) => state.correspondenceDetails.correspondenceInfo.tasksUnrelatedToAppeal);

  // Track if user is on the second page of the modal (auto-text selection)
  const [isSecondPage, setIsSecondPage] = useState(false);
  const [taskTypeOptions, setTaskTypeOptions] = useState([]);

  // Main task content for the first page
  const [taskContent, setTaskContent] = useState('');
  // Additional content generated from selected auto-texts on the second page
  const [additionalContent, setAdditionalContent] = useState('');
  const [selectedTaskType, setSelectedTaskType] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  // Tracks selected checkboxes for auto-text selections on the second page
  const [autoTextSelections, setAutoTextSelections] = useState([]);

  // Options for checkboxes on the second page derived from the `autoTexts` prop
  const checkboxData = autoTexts;

  // Filters task type options based on unrelated tasks, excluding already selected tasks
  const getFilteredTaskTypeOptions = () => {
    return INTAKE_FORM_TASK_TYPES.unrelatedToAppeal.
      filter((option) => !unrelatedTaskList.some((existingTask) => existingTask.label.toLowerCase() === option.label.toLowerCase())).
      map((option) => ({ value: option.value, label: option.label }));
  };

  // Set task type options initially based on unrelated tasks
  useEffect(() => {
    setTaskTypeOptions(getFilteredTaskTypeOptions());
  }, [unrelatedTaskList]);

  // Submit disabled if task type is not selected, the page is loading, or task content and additional are not filled out
  const isSubmitDisabled = !(taskContent || additionalContent) || !selectedTaskType || isLoading;

  // Handle task type selection, stores the selected task type
  const updateTaskType = (newType) => setSelectedTaskType(newType.value);

  // Updates main task content on first page
  const updateTaskContent = (newContent) => setTaskContent(newContent);

  // Updates additional content on the second page
  const updateAdditionalContent = (newContent) => setAdditionalContent(newContent);

  // Handles toggling of auto-text checkboxes
  const handleToggleCheckbox = (checkboxText) => {
    setAutoTextSelections((prevSelections) => {
      // Adds/removes selected text from autoTextSelections array
      const newSelections = prevSelections.includes(checkboxText) ?
        prevSelections.filter((item) => item !== checkboxText) :
        [...prevSelections, checkboxText];

      // Updates additional content to comma-separated string
      setAdditionalContent(newSelections.join(', \n'));

      return newSelections;
    });
  };

  // Navigate to the second page when "Next" is clicked
  const handleNext = () => setIsSecondPage(true);

  // Handles form submission when "Submit" is clicked on the second page
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
      await dispatch(addTaskNotRelatedToAppeal(correspondence, newTask));

      // Resets fields and state after submission
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

  // Prevent rendering of modal if not open
  if (!isOpen) {
    return null;
  }

  return (
    <Modal
      // Dynamic title for each page
      title={isSecondPage ? 'Add autotext to task' : 'Add task to correspondence'}
      closeHandler={handleClose}
      confirmButton={
        <Button
          // "Submit" on second page, "Next" on first page
          onClick={isSecondPage ? handleSubmit : handleNext}
          disabled={isSecondPage ? isSubmitDisabled : false}
        >
          {isLoading ? 'Loading...' : isSecondPage ? 'Submit' : 'Next'}
        </Button>
      }
      cancelButton={
        isSecondPage ? (
          <div className="action-buttons">
            <Button linkStyling onClick={handleClose} disabled={isLoading}>
              Cancel
            </Button>
            <Button classNames={['usa-button-secondary', 'back-button']} onClick={handleBack} disabled={isLoading}>
              Back
            </Button>
          </div>
        ) : (
          <Button linkStyling onClick={handleClose} disabled={isLoading}>
            Cancel
          </Button>
        )
      }
    >
      <div className={`add-task-modal-container ${isSecondPage ? 'scrollable-content' : ''}`}>
        {isSecondPage ? (
          // Second page with checkboxes and additional TextareaField
          <div className="checkbox-modal-size-corr-details">
            {checkboxData.map((checkboxText) => (
              <Checkbox
                key={checkboxText}
                name={checkboxText}
                onChange={() => handleToggleCheckbox(checkboxText)}
                value={autoTextSelections.includes(checkboxText)}
              />
            ))}
            <TextareaField
              name="selectedAutotext"
              label="Selected autotext"
              value={additionalContent}
              onChange={updateAdditionalContent}
              classNames={['task-selection-dropdown-box-corr-details']}
              styling={ninetySixWidthFormInput}
            />
          </div>
        ) : (
          // First page with task selection and main TextareaField
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
            <TextareaField
              name="content"
              label="Provide context and instructions on this task"
              value={taskContent}
              onChange={updateTaskContent}
              classNames={['task-selection-dropdown-box']}
              styling={maxWidthFormInput}
            />
          </div>
        )}
      </div>
    </Modal>
  );
};

AddTaskModalCorrespondenceDetails.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  handleClose: PropTypes.func.isRequired,
  correspondence: PropTypes.object.isRequired,
  setIsTasksUnrelatedSectionExpanded: PropTypes.func.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddTaskModalCorrespondenceDetails;
