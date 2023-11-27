/*
  ✓ IntakeForm
    ✓ Step2:AddTasksAppeals
      AddUnrelatedTasks (AddUnrelatedTaskView)
        ✓ AddTaskForm   <-- Reusable component (AddTaskView)
      AddRelatedTasks (AddAppealRelatedTaskView)
        RelatedAppeal (ExistingAppealTasksView)
          ✓ AddTaskForm <-- Reusable component (AddTaskView)

  // Get Tasks for this appeal from the store
  // Implement add task button onclick
  // Implement removeTask callback
*/

import React from 'react';
import TextareaField from '../../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Button from '../../../../../components/Button';
import PropTypes from 'prop-types';

const dropdownOptions = [
  { value: 'CAVC Correspondence', label: 'CAVC Correspondence' },
  { value: 'Congressional interest', label: 'Congressional interest' },
  { value: 'Death certificate', label: 'Death certificate' },
  { value: 'FOIA request', label: 'FOIA request' },
  { value: 'Other motion', label: 'Other motion' },
  { value: 'Power of attorney-related', label: 'Power of attorney-related' },
  { value: 'Privacy act request', label: 'Privacy act request' },
  { value: 'Privacy complaint', label: 'Privacy complaint' },
  { value: 'Status inquiry', label: 'Status inquiry' }
];

const AddTaskView = (props) => {
  const task = props.task;

  const updateTaskContent = (newContent) => {
    const newTask = { id: task.id, appealId: task.appealId, type: task.type, content: newContent };

    props.taskUpdatedCallback(newTask);
  };

  const updateTaskType = (newType) => {
    const newTask = { id: task.id, appealId: task.appealId, type: newType.value, content: task.content };

    props.taskUpdatedCallback(newTask);
  };

  return (
    <div key={task.id} style={{ display: 'block', marginRight: '2rem' }}>
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
              options={dropdownOptions}
              defaultValue={dropdownOptions[task.type]}
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
            name="Add"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            classNames={['cf-btn-link', 'cf-left-side']}
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
  displayRemoveCheck: PropTypes.bool.isRequired
};

export default AddTaskView;
