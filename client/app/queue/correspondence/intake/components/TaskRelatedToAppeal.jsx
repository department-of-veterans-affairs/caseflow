import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { addNewAppealRelatedTask } from '../../correspondenceReducer/correspondenceActions';
import Button from '../../../../components/Button';
import TextareaField from '../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../components/ReactSelectDropdown';

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

const TaskRelatedToAppeal = (props) => {
  // console.log(taskRelatedAppeals);

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
              options={dropdownOptions}
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
            {(props.deleteVisible && <Button
            name="Remove"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            onClick={() => props.deleteHandler(props.task)}
            classNames={['cf-btn-link', 'cf-right-side']}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
          </Button>)}
        </div>
      </div>
    </div>
  );
};

export default TaskRelatedToAppeal;
