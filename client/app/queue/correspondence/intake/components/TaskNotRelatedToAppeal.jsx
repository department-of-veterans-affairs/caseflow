import React, { useState } from 'react';
// import Dropdown from '../../../../components/Dropdown';
import TextareaField from '../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../components/ReactSelectDropdown';
import PropTypes from 'prop-types';
import Button from '../../../../components/Button';
import EditableField from '../../../../components/EditableField';
import SaveableTextArea from '../../../../components/SaveableTextArea';
import TextField from '../../../../components/TextField';

const TaskNotRelatedToAppeal = (props) => {

  const dummyOptions = [
    { value: 0, label: 'Abeyance' },
    { value: 1, label: 'Attorney Inquiry' },
    { value: 2, label: 'CAVC Correspondence' }
  ];

  const [selectedTaskType, setSelectedTaskType] = useState(-1);

  const handleChangeTaskType = (newType) => {
    setSelectedTaskType(newType);
  };

  return (
    <div key={props.key} style={{ display: 'block', marginRight: '2rem' }}>
      <div className="gray-border" style={{ display: 'flex', padding: '2rem 2rem', marginLeft: '3rem', width: '50rem' }}>
      {/* <div className="gray-border" style={{ marginLeft: '3rem', maxWidth: '50rem' }} > */}
      {/* <div> */}
        <div
          style={
            { width: '45rem' }
          }
        >
          <ReactSelectDropdown
            options={dummyOptions}
            defaultValue={{ value: -1, label: 'Select...' }}
            label="Task"
            style={{ width: '50rem' }}
            onChangeMethod={(selectedOption) => handleChangeTaskType(selectedOption.value)}
            className="date-filter-type-dropdown"
            // onChange={(option) => onClickIssueAction(issue.index, option)}
          />
          <div style={{ padding: '1.5rem' }} />
          {/* <hr /> */}
          <TextareaField
            name="Task Information"
            label="Provide context and instruction on this task"
            defaultText=""
            // style={
            //   { display: 'flex', justifyContent: 'flex-end', paddingLeft: '1rem', marginLeft: '0.5rem', minWidth: '500px' }
            // }
          />
          <Button
            name="Remove"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            onClick={props.removeTask}
            classNames={['cf-btn-link', 'cf-left-side']} >
            Remove task
          </Button>
          {/* <p onClick={props.removeTask}>Remove task</p> */}
        </div>
      </div>
    </div>
  );
};

TaskNotRelatedToAppeal.propTypes = {
  removeTask: PropTypes.func,
};

export default TaskNotRelatedToAppeal;
