/* eslint-disable max-len */
import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
import Checkbox from '../../../../../components/Checkbox';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';
import { useDispatch } from 'react-redux';
import { createCorrespondenceAppealTask } from '../../../correspondenceDetailsReducer/correspondenceDetailsActions';
import { maxWidthFormInput, corrDetailsModal } from '../../../../../hearings/components/details/style';
import COPY from '../../../../../../COPY';

const AddRelatedTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  correspondence,
  appeal,
  tasks,
  autoTexts
}) => {
  const dispatch = useDispatch();

  // --==Future Work==--
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

  // Filters task type options based on related tasks, excluding already selected tasks
  const getFilteredTaskTypeOptions = () => {
    return INTAKE_FORM_TASK_TYPES.relatedToAppeal.
      filter((option) => !tasks.some((existingTask) =>
        existingTask.label.toLowerCase() === option.label.toLowerCase())).
      map((option) => ({ value: option.value, label: option.label }));
  };

  // Set task type options initially based on related tasks
  useEffect(() => {
    setTaskTypeOptions(getFilteredTaskTypeOptions());
  }, [tasks]);

  // Submit disabled if task type is not selected,
  // the page is loading, or task content and additional are not filled out
  const isSubmitDisabled = !(taskContent || additionalContent) || !selectedTaskType || isLoading;

  // Handle task type selection, stores the selected task type
  const updateTaskType = (newType) => setSelectedTaskType(newType.value);

  // Updates main task content on first page
  const updateTaskContent = (newContent) => setTaskContent(newContent);

  // Updates additional content on the second page
  const updateAdditionalContent = (newContent) => setAdditionalContent(newContent);

  const isNextDisabled = !selectedTaskType;

  // Helper function to determine the button text
  const getButtonText = () => {
    if (isLoading) {
      return 'Loading...';
    }

    return isSecondPage ? 'Add task' : 'Next';
  };

  const allClearAndClose = () => {
    setTaskContent('');
    setAdditionalContent('');
    setSelectedTaskType(null);
    setIsSecondPage(false);
    setAutoTextSelections([]);
    handleClose();
  };

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
      appeal_id: appeal.id,
      klass: selectedTaskType.klass,
      assigned_to: selectedTaskType.assigned_to,
      content: combinedContent,
      label: taskTypeOptions.find((option) => option.value === selectedTaskType)?.label,
      assignedOn: new Date().toISOString(),
      instructions: [combinedContent],
      correspondence_uuid: correspondence.correspondence_uuid
    };

    setIsLoading(true);

    try {
      await dispatch(createCorrespondenceAppealTask(newTask, correspondence, appeal.id));

      // Resets fields and state after submission
      allClearAndClose();
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
      title={isSecondPage ? 'Add autotext to task' : 'Add task to appeal'}
      closeHandler={allClearAndClose}
      confirmButton={
        <Button
          // "Submit" on second page, "Next" on first page
          onClick={isSecondPage ? handleSubmit : handleNext}
          disabled={isSecondPage ? isSubmitDisabled : isNextDisabled}
        >
          {getButtonText()}
        </Button>
      }
      cancelButton={
        isSecondPage ? (
          <div className="action-buttons">
            <Button linkStyling onClick={allClearAndClose} disabled={isLoading}>
              Cancel
            </Button>
            <Button classNames={['usa-button-secondary', 'back-button']} onClick={handleBack} disabled={isLoading}>
              Back
            </Button>
          </div>
        ) : (
          <Button linkStyling onClick={allClearAndClose} disabled={isLoading}>
            Cancel
          </Button>
        )
      }
      className="add-related-task-modal"
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
              styling={corrDetailsModal}
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
              isSearchable={false}
            />
            <TextareaField
              name="content"
              label={COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL}
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

AddRelatedTaskModalCorrespondenceDetails.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  handleClose: PropTypes.func.isRequired,
  correspondence: PropTypes.object.isRequired,
  tasks: PropTypes.array,
  appeal: PropTypes.object.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddRelatedTaskModalCorrespondenceDetails;

