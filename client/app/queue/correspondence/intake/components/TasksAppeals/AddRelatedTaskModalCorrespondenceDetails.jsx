import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
// import Checkbox from '../../../../../components/Checkbox';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';
import { useDispatch, useSelector } from 'react-redux';
import { addTaskNotRelatedToAppeal } from '../../../correspondenceDetailsReducer/correspondenceDetailsActions';
import { maxWidthFormInput } from '../../../../../hearings/components/details/style';
// import { maxWidthFormInput, ninetySixWidthFormInput } from '../../../../../hearings/components/details/style';

const customSelectStyless = {
  dropdownIndicator: () => ({
    width: '80%'
  }),

  control: (styles) => {
    return {
      ...styles,
      alignContent: 'center',
      borderRadius: 0,
      border: '1px solid black'
    };
  },

  menu: () => ({
    boxShadow: '0 0 0 1px hsla(0,0%,0%,0.1), 0 4px 11px hsla(0,0%,0%,0.1)',
    marginTop: '8px'
  }),

  valueContainer: (styles) => ({

    ...styles,
    lineHeight: 'normal',
    // this is a hack to fix a problem with changing the height of the dropdown component.
    // Changing the height causes problems with text shifting.
    marginTop: '-10%',
    marginBottom: '-10%',
    paddingTop: '-10%',
    minHeight: '140px',
    borderRadius: 50

  }),
  singleValue: (styles) => {
    return {
      ...styles,
      alignContent: 'center',
    };
  },

  placeholder: (styles) => ({
    ...styles,
    color: 'black',
  }),

  option: (styles, { isFocused }) => ({
    color: 'black',
    fontSize: '17px',
    padding: '8px 12px',
    backgroundColor: isFocused ? 'white' : 'null',
    ':hover': {
      ...styles[':hover'],
      backgroundColor: '#5b616b',
      color: 'white',
    }
  })
};

const AddRelatedTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  appeal,
  tasks
  // autoTexts
}) => {
  const dispatch = useDispatch();

  // --==Future Work==--
  // Track if user is on the second page of the modal (auto-text selection)
  // const [isSecondPage, setIsSecondPage] = useState(false);
  const [taskTypeOptions, setTaskTypeOptions] = useState([]);

  // Main task content for the first page
  const [taskContent, setTaskContent] = useState('');

  // --==Future Work==--
  // Additional content generated from selected auto-texts on the second page
  // const [additionalContent, setAdditionalContent] = useState('');
  const [selectedTaskType, setSelectedTaskType] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  // --==Future Work==--
  // Tracks selected checkboxes for auto-text selections on the second page
  // const [autoTextSelections, setAutoTextSelections] = useState([]);

  // --==Future Work==--
  // Options for checkboxes on the second page derived from the `autoTexts` prop
  // const checkboxData = autoTexts;

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

  // --==Future Work==--
  // Submit disabled if task type is not selected, the page is loading,
  // or task content and additional are not filled out
  // const isSubmitDisabled = !(taskContent || additionalContent) || !selectedTaskType || isLoading;

  // Handle task type selection, stores the selected task type
  const updateTaskType = (newType) => setSelectedTaskType(newType.value);

  // Updates main task content on first page
  const updateTaskContent = (newContent) => setTaskContent(newContent);

  // --==Future Work==--
  // Updates additional content on the second page
  // const updateAdditionalContent = (newContent) => setAdditionalContent(newContent);

  // --==Future Work==--
  // Handles toggling of auto-text checkboxes
  // const handleToggleCheckbox = (checkboxText) => {
  //   setAutoTextSelections((prevSelections) => {
  //     // Adds/removes selected text from autoTextSelections array
  //     const newSelections = prevSelections.includes(checkboxText) ?
  //       prevSelections.filter((item) => item !== checkboxText) :
  //       [...prevSelections, checkboxText];

  //     // Updates additional content to comma-separated string
  //     setAdditionalContent(newSelections.join(', \n'));

  //     return newSelections;
  //   });
  // };

  // --==Future Work==--
  // Navigate to the second page when "Next" is clicked
  // const handleNext = () => setIsSecondPage(true);

  // Handles form submission when "Submit" is clicked on the second page
  const handleSubmit = async () => {

    // --==Future Work==--
    // const combinedContent = taskContent ? `${taskContent}\n${additionalContent}` : additionalContent;

    const newTask = {
      klass: selectedTaskType.klass,
      assigned_to: selectedTaskType.assigned_to,
      // content: combinedContent,
      content: taskContent,
      label: taskTypeOptions.find((option) => option.value === selectedTaskType)?.label,
      assignedOn: new Date().toISOString(),
      // instructions: [combinedContent],
      instructions: [taskContent],
    };

    setIsLoading(true);

    try {
      await dispatch(addTaskNotRelatedToAppeal(correspondence, newTask));

      // Resets fields and state after submission
      setTaskContent('');
      // setAdditionalContent('');
      setSelectedTaskType(null);
      // setIsSecondPage(false);
      // setAutoTextSelections([]);
      handleClose();
    } catch (error) {
      console.error('Error while adding task:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // --==Future Work==--
  // Navigate back to the first page
  // const handleBack = () => setIsSecondPage(false);

  // Prevent rendering of modal if not open
  if (!isOpen) {
    return null;
  }

  return (
    <Modal
      // --==Future Work==--
      // Dynamic title for each page
      // title={isSecondPage ? 'Add autotext to task' : 'Add task to correspondence'}
      title="Add task to appeal"
      closeHandler={handleClose}
      confirmButton={
        <Button
          // --==Future Work==--
          // "Submit" on second page, "Next" on first page
          // onClick={isSecondPage ? handleSubmit : handleNext}
          // disabled={isSecondPage ? isSubmitDisabled : false}
          onClick={handleSubmit}
          disabled={false}
        >
          {isLoading ? 'Loading...' : 'Submit'}
        </Button>
      }
      cancelButton={
        // --==Future Work==--
        // isSecondPage ? (
        //   <div className="action-buttons">
        //     <Button linkStyling onClick={handleClose} disabled={isLoading}>
        //       Cancel
        //     </Button>
        //     <Button classNames={['usa-button-secondary', 'back-button']} onClick={handleBack} disabled={isLoading}>
        //       Back
        //     </Button>
        //   </div>
        // ) : (
        <Button linkStyling onClick={handleClose} disabled={isLoading}>
          Cancel
        </Button>
        // )
      }
    >
      {/* --==Future Work==-- */}
      {/* <div className={`add-task-modal-container ${isSecondPage ? 'scrollable-content' : ''}`}>/ */}
      <div className="add-task-modal-container">
        {/* --==Future Work==-- */}
        {/* {isSecondPage ? (
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
        ) : (*/

          // First page with task selection and main TextareaField
          <div className="task-selection-dropdown-box">
            <div id="reactSelectContainer" className="select-container-styles">
              <label className="task-selection-title">Task</label>
              <Select
                placeholder="Select..."
                options={taskTypeOptions}
                classNamePrefix="react-select"
                className="add-task-dropdown-style"
                onChange={updateTaskType}
                styles={customSelectStyless}
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
          </div>
        // )
        }
      </div>
    </Modal>
  );
};

AddRelatedTaskModalCorrespondenceDetails.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  handleClose: PropTypes.func.isRequired,
  appeal: PropTypes.object.isRequired,
  tasks: PropTypes.object,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddRelatedTaskModalCorrespondenceDetails;
