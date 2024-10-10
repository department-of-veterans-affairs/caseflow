import React, { useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import Button from '../../../../../components/Button';
import Select from 'react-select';
import PropTypes from 'prop-types';

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

        <div className="gray-border add-task-container">
          <div className=" task-selection-box-for-new-tasks">
            <div className="task-selection-dropdown-box">
              <div id="reactSelectContainer"
                className="select-container-styles">
                <label className="task-selection-title">Task</label>
                <Select
                  placeholder="Select..."
                  options={props.availableTaskTypeOptions}
                  defaultValue={objectForSelectedTaskType()}
                  onChange={(selectedOption) => updateTaskType(selectedOption)}
                  styles={customSelectStyless}
                  className="add-task-dropdown-style"
                  aria-label="dropdown"
                />
              </div>
              <div className="provide-context-text-styling" />
              <TextareaField
                name="content"
                label="Provide context and instruction on this task"
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
