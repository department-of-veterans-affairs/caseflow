import React, { useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Button from '../../../../../components/Button';
import PropTypes from 'prop-types';

const autotextOptions = [
  'Address updated in VACOLS',
  'Decision sent to Senator or Congressman mm/dd/yy',
  'Interest noted in telephone call of mm/dd/yy',
  'Interest noted in evidence file regarding current appeal',
  'Email - responded via email on mm/dd/yy',
  'Email - written response req; confirmed receipt via email to Congress office on mm/dd/yy',
  'Possible motion pursuant to BVA decision dated mm/dd/yy',
  'Motion pursuant to BVA decision dated mm/dd/yy',
  'Statement in support of appeal by appellant',
  'Statement in support of appeal by rep',
  'Medical evidence X-Rays submitted or referred by',
  'Medical evidence clinical reports submitted or referred by',
  'Medical evidence examination reports submitted or referred by',
  'Medical evidence progress notes submitted or referred by',
  'Medical evidence physician\'s medical statement submitted or referred by',
  'C&P exam report',
  'Consent form (specify)',
  'Withdrawal of issues',
  'Response to BVA solicitation letter dated mm/dd/yy',
  'VAF 9 (specify)'
];

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
        autoTextOutput += `${autotextOptions[id] }\n`;
      });
    }
    updateTaskContent(autoTextOutput);
    handleModalToggle();
  };

  return (
    <div key={task.id} style={{ display: 'block', marginRight: '2rem' }}>
      {modalVisible &&
        <CheckboxModal
          checkboxData={autotextOptions}
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
  allTaskTypeOptions: PropTypes.array.isRequired,
  availableTaskTypeOptions: PropTypes.array.isRequired
};

export default AddTaskView;
