import React, { useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import Button from '../../../../../components/Button';
import Select from 'react-select';
import { css } from 'glamor';
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
    boxShadow: '1px 1px 10px grey',
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
    fontSize: '25px',
    paddingTop: '10px',
    paddingBottom: '10px',
    paddingLeft: '20px',
    backgroundColor: isFocused ? 'white' : 'null',
    ':hover': {
      ...styles[':hover'],
      backgroundColor: '#5c9ceb',
      color: 'black',
    }
  })
};
const selectContainerStyless = css({
  width: '100%',
  display: 'inline-block',
});

const AddTaskView = (props) => {
  const task = props.task;
  const [modalVisible, setModalVisible] = useState(false);

  const objectForSelectedTaskType = () => {
    return props.allTaskTypeOptions.find((option) => {
      return option.value === task.type;
    });
  };

  const updateTaskContent = (newContent) => {
    const newTask = { id: task.id, appealId: task.appealId, type: task.type, label: task.label, content: newContent };

    props.taskUpdatedCallback(newTask);
  };

  const updateTaskType = (newType) => {
    const newTask = { id: task.id, appealId: task.appealId, type: newType.value, label: newType.label, content: task.content };

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

          <div id="reactSelectContainer"
            {...selectContainerStyless}>

            <label style={{ marginTop: '5px', marginBottom: '5px', marginLeft: '1px' }}>Task</label>
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
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired
};

export default AddTaskView;
