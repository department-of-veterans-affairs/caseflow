import React, { useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Button from '../../../../../components/Button';
import PropTypes from 'prop-types';

const AddTaskView = (props) => {
  const task = props.task;
  const [modalVisible, setModalVisible] = useState(false);

  const objectForSelectedTaskType = () => {
    return props.allTaskTypeOptions.find((option) => {
      return option.value === task.type;
    });
  };

  const updateTaskContent = (newContent) => {
    const newTask = { id: task.id, appealId: task.appealId, type: task.type, content: newContent };

    props.taskUpdatedCallback(newTask);
  };

  const updateTaskType = (newType) => {
    const newTask = { id: task.id, appealId: task.appealId, type: newType.value, content: task.content };

    props.taskUpdatedCallback(newTask);
  };

  const handleModalToggle = () => {
    setModalVisible(!modalVisible);
  };

  const handleAutotext = (autoTextValues) => {
    let autoTextOutput = '';

    if (autoTextValues.length > 0) {
      autoTextValues.forEach((id) => {
        autoTextOutput += `${props.autoTexts[id] }\n`;
      });
    }
    updateTaskContent(autoTextOutput);
    handleModalToggle();
  };

  return (
    <div key={task.id} style={{ display: 'block', marginRight: '2rem' }}>
      {modalVisible &&
        <CheckboxModal
          checkboxData={props.autoTexts}
          toggleModal={handleModalToggle}
          closeHandler={handleModalToggle}
          handleAccept={handleAutotext}
        />
      }
      <div className="gray-border"
        style={
          { display: 'block', padding: '2rem 2rem', marginLeft: '3rem', marginBottom: '3rem', width: '50rem' }
        }>
        <div
          style={
            { width: '45rem' }
          }
        >
          <div id="reactSelectContainer">
            <ReactSelectDropdown
              options={props.availableTaskTypeOptions}
              defaultValue={objectForSelectedTaskType()}
              label="Task"
              style={{ width: '50rem' }}
              onChangeMethod={(selectedOption) => updateTaskType(selectedOption)}
              className="date-filter-type-dropdown"
            />
          </div>
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="content"
            label="Provide context and instruction on this task"
            value={task.content}
            onChange={updateTaskContent}
          />
          <Button
            id="addAutotext"
            name="Add"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            classNames={['cf-btn-link', 'cf-left-side']}
            onClick={handleModalToggle}
          >
            Add autotext
          </Button>
          {props.displayRemoveCheck &&
            <Button
              name="Remove"
              styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
              onClick={() => props.removeTask(task.id)}
              classNames={['cf-btn-link', 'cf-right-side']}
            >
              <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
            </Button>
          }
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
  filteredTaskOptions: PropTypes.array.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  availableTaskTypeOptions: PropTypes.array.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default AddTaskView;
