import React from 'react';
import Dropdown from '../../../../components/Dropdown';
import TextareaField from '../../../../components/TextareaField';

const TaskNotRelatedToAppeal = (task) => {
  return (
    <div style={{ display: 'inline-block', marginRight: '2rem' }} key={i}>
      <div className="gray-border" style={{ padding: '2rem 2rem', marginLeft: '3rem' }}>
        <div style={
          { display: 'flex', justifyContent: 'flex-end', paddingLeft: '1rem', marginLeft: '0.5rem', minWidth: '500px' }
        }>
          <Dropdown
            name="Task"
            label="Task"
            options={[['Option1', 'Option 1'], ['Option 2'], ['Option 3']]}
            defaultText="Select..."
            style={{ display: 'flex', width: '100%', marginRight: '1rem' }}
            // onChange={(option) => onClickIssueAction(issue.index, option)}
          />
          <div style={{ marginRight: '10rem' }} />
          <hr />
          <TextareaField
            name="Task Information"
            label="Provide context and instruction on this task"
            defaultText=""
          />
        </div>
      </div>
    </div>
);
};

export default TaskNotRelatedToAppeal;
