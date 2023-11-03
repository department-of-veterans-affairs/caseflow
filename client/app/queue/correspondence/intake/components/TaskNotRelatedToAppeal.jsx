import React, { useState } from 'react';
import Dropdown from '../../../../components/Dropdown';
import TextareaField from '../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../components/ReactSelectDropdown';

const TaskNotRelatedToAppeal = (props) => {

  const dummyOptions = [
    { value: 0, label: 'Abeyance' },
    { value: 1, label: 'Attorney Inquiry' },
    { value: 2, label: 'CAVC Correspondence' }
  ];

  const [selectedTaskType, setSelectedTaskType] = useState(-1);

  const handleChangeTaskType = (newType) => {
    setSelectedTaskType(newType);
  }

  return (
    <div key={props.key} style={{ display: 'inline-block', marginRight: '2rem' }}>
      <div className="gray-border" style={{ padding: '2rem 2rem', marginLeft: '3rem' }}>
        <div style={
          { display: 'flex', justifyContent: 'flex-end', paddingLeft: '1rem', marginLeft: '0.5rem', minWidth: '500px' }
        }>
          <ReactSelectDropdown
            options={dummyOptions}
            defaultValue={{ value: -1, label:'Select...' }}
            label="Task"
            onChangeMethod={(selectedOption) => handleChangeTaskType(selectedOption.value)}
            className="date-filter-type-dropdown"
            // onChange={(option) => onClickIssueAction(issue.index, option)}
          />
          <div style={{ marginRight: '10rem' }} />
          <hr />
          <TextareaField
            name="Task Information"
            label="Provide context and instruction on this task"
            defaultText=""
          />
          <p onClick={props.removeTask}>Remove task</p>
        </div>
      </div>
    </div>
  );
};

export default TaskNotRelatedToAppeal;
