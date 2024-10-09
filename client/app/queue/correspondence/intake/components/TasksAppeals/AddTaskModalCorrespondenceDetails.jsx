import React, { useState, useEffect} from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../../../components/Modal';
import Button from '../../../../../components/Button';
import TextareaField from '../../../../../components/TextareaField';
import Select from 'react-select';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';

const AddTaskModalCorrespondenceDetails = ({
  isOpen,
  handleClose,
  onSubmit,
  task,
  availableTaskTypeOptions,
  taskUpdatedCallback,
  displayRemoveCheck,
  removeTask,
}) => {
  const [modalVisible, setModalVisible] = useState(false);
  const allTaskTypeOptions = INTAKE_FORM_TASK_TYPES.unrelatedToAppeal;
  useEffect(() => {
    console.log(allTaskTypeOptions)
  }, []);

  // const objectForSelectedTaskType = () => {
  //   return allTaskTypeOptions.find((option) => {
  //     return option.value.assigned_to === task.type.assigned_to;
  //   });
  // };

  // const updateTaskContent = (newContent) => {
  //   const updatedTask = { ...task, content: newContent };
  //   taskUpdatedCallback(updatedTask);
  // };

  const updateTaskType = (newType) => {
    const updatedTask = { ...task, type: newType.value, label: newType.label };
    taskUpdatedCallback(updatedTask);
  };

  const handleModalToggle = () => {
    setModalVisible(!modalVisible);
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
          onClick={() => {
            onSubmit(task);
            handleClose();
          }}
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
            options={availableTaskTypeOptions}
            // defaultValue={objectForSelectedTaskType()}
            onChange={updateTaskType}
            className="add-task-dropdown-style"
            aria-label="dropdown"
          />
        </div>

        <TextareaField
          name="content"
          label="Provide context and instruction on this task"
          // value={task.content}
          // onChange={updateTaskContent}
        />

        <Button
          id="addAutotext"
          name="Add"
          classNames={['cf-btn-link', 'cf-left-side', 'add-autotext-button']}
          onClick={handleModalToggle}
        >
          Add autotext
        </Button>

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
  onSubmit: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  availableTaskTypeOptions: PropTypes.array.isRequired,
  taskUpdatedCallback: PropTypes.func.isRequired,
  autoTexts: PropTypes.array.isRequired,
  handleClear: PropTypes.func.isRequired,
  displayRemoveCheck: PropTypes.bool.isRequired,
  removeTask: PropTypes.func.isRequired,
};

export default AddTaskModalCorrespondenceDetails;
