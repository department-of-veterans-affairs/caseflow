import React from 'react';
import Button from '../../../../components/Button';
import TextareaField from '../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../components/ReactSelectDropdown';

const AddRelatedTaskView = () => {
  return (
    <div key={'KEYVALUE'} style={{ display: 'block', marginRight: '2rem' }}>
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
              options={[]}
              defaultValue={[]}
              label="Task"
              style={{ width: '50rem' }}
              onChangeMethod={(null)}
              className="date-filter-type-dropdown"
            />
          </div>
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="content"
            label="Provide context and instruction on this task"
            value={null}
            onChange={null}
          />
          <Button
            name="Add"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            classNames={['cf-btn-link', 'cf-left-side']}
          >
              Add autotext
          </Button>
          <Button
            name="Remove"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            onClick={() => null}
            classNames={['cf-btn-link', 'cf-right-side']}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
          </Button>
        </div>
      </div>
    </div>
  );
};

export default AddRelatedTaskView;
