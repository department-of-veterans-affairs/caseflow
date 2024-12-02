import React, { useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import Button from '../../../../../components/Button';
import Select from 'react-select';
import PropTypes from 'prop-types';
import COPY from '../../../../../../COPY';

const AddTaskView = (props) => {
  const task = props.task;
  const [modalVisible, setModalVisible] = useState(false);

  const objectForSelectedTaskType = () => {
    return props.allTaskTypeOptions.find((option) => {
      return option.value.assigned_to === task.type.assigned_to;
    });
  };

  const updateTaskContent = (newContent) => {
    const newTask = { id: task.id, appealId: task.appealId, type: task.type, label: task.label, content: newContent };

    props.taskUpdatedCallback(newTask);
  };

  const updateTaskType = (newType) => {
    const newTask =
      { id: task.id, appealId: task.appealId, type: newType.value, label: newType.label, content: task.content };

    props.taskUpdatedCallback(newTask);
  };

  const handleModalToggle = () => {
    setModalVisible(!modalVisible);
  };

  const handleAutotext = (autoTextValues) => {
    let autoTextOutput = '';

    if (task.content) {
      autoTextOutput = task.content;
    }

    if (autoTextValues.length > 0) {
      autoTextValues.forEach((id) => {
        autoTextOutput += `${props.autoTexts[id] }\n`;
      });
    }
    updateTaskContent(autoTextOutput);
    handleModalToggle();
  };

  return (
    <div className="margin-bottom-for-add-task-view">
      <div className="new-tasks-gray-border-styling" key={task.id}>
        {modalVisible &&
        <CheckboxModal
          checkboxData={props.autoTexts}
          toggleModal={handleModalToggle}
          closeHandler={handleModalToggle}
          handleAccept={handleAutotext}
          handleClear={props.handleClear}
        />
        }

        <div>
          <div className=" task-selection-box-for-new-tasks">
            <div className="task-selection-dropdown-box">
              <div className="task-selection-dropdown-box">
                <label className="task-selection-title">Task</label>
                <Select
                  placeholder="Select..."
                  options={props.availableTaskTypeOptions}
                  defaultValue={objectForSelectedTaskType()}
                  onChange={(selectedOption) => updateTaskType(selectedOption)}
                  classNamePrefix="react-select"
                  className="add-task-dropdown-style"
                  aria-label="dropdown"
                />
              </div>
              <div className="provide-context-text-styling" />
              <TextareaField
                name="content"
                label={COPY.PLEASE_PROVIDE_CONTEXT_AND_INSTRUCTIONS_LABEL}
                value={task.content}
                onChange={updateTaskContent}
              />
              <Button
                id="addAutotext"
                name="Add"
                classNames={['cf-btn-link', 'cf-left-side', 'add-autotext-button']}
                onClick={handleModalToggle}
              >
            Add autotext
              </Button>
              {props.displayRemoveCheck &&
            <Button
              name="Remove"
              onClick={() => props.removeTask(task.id)}
              classNames={['cf-btn-link', 'cf-right-side', 'remove-task-button']}
            >
              <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
            </Button>
              }
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

AddTaskView.propTypes = {
  removeTask: PropTypes.func.isRequired,
  task: PropTypes.object.isRequired,
  taskUpdatedCallback: PropTypes.func.isRequired,
  displayRemoveCheck: PropTypes.bool.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  availableTaskTypeOptions: PropTypes.array.isRequired,
  onChange: PropTypes.func,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      value: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
      displayText: PropTypes.string,
    })
  ),
  defaultValue: PropTypes.object,
  label: PropTypes.string,
  onChangeMethod: PropTypes.func,
  className: PropTypes.string,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
  handleClear: PropTypes.func
};

export default AddTaskView;
