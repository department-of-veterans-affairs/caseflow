import React from 'react';
import PropTypes from 'prop-types';
import ReactSelectDropdown from '../../../client/app/components/ReactSelectDropdown';
import DateSelector from './DateSelector';
import Button from './Button';

const dateDropdownMap = [
  { value: 0, label: 'Between these dates' },
  { value: 1, label: 'Before this date' },
  { value: 2, label: 'After this date' },
  { value: 3, label: 'On this date' }
];

const TaskCompletedDatePicker = (props) => {
  const getDatePickerElements = () => {
    const taskCompletedDateFilterStates = props.taskCompletedDateFilterStates;

    switch (props.taskCompletedDateState) {
    case taskCompletedDateFilterStates.BETWEEN: return (
      <div style={{ margin: '5% 5%' }}>
        <DateSelector onChange={props.handleTaskCompletedDateChange} label="From" type="date" />
        <DateSelector onChange={props.handleTaskCompletedSecondaryDateChange} label="To" type="date" />
      </div>);
    case taskCompletedDateFilterStates.BEFORE: return (
      <div style={{ margin: '5% 5%' }}>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} label="To" type="date" />
      </div>
    );
    case taskCompletedDateFilterStates.AFTER: return (
      <div style={{ margin: '5% 5%' }}>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} type="date" />
      </div>
    );
    case taskCompletedDateFilterStates.ON: return (
      <div style={{ margin: '5% 5%' }}>
        <div style={{ marginTop: '5%' }}>Date Completed:</div>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} type="date" />
      </div>
    );

    default:
    }
  };

  return <div id="dropdown">
    <div style={{ marginLeft: '5%', marginRight: '5%' }}>
      <ReactSelectDropdown
        label="Date filter parameters"
        options={dateDropdownMap}
        onChangeMethod={props.onChangeMethod} />
    </div>

    <div style={{ width: '100%', margin: 'auto' }}>
      {getDatePickerElements()}
    </div>
    <div style={{ margin: '10px 20px', display: 'flex', justifyContent: 'end', width: '190px' }}>
      <Button onClick={props.handleTaskCompletedApplyFilter}>Apply filter</Button>
    </div>
  </div>;
};

TaskCompletedDatePicker.propTypes = {
  taskCompletedDateFilterStates: PropTypes.object,
  taskCompletedDateState: PropTypes.number,
  handleTaskCompletedApplyFilter: PropTypes.func.isRequired,
  handleTaskCompletedDateChange: PropTypes.func.isRequired,
  handleTaskCompletedSecondaryDateChange: PropTypes.func.isRequired,
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
  disabled: PropTypes.bool,
  customPlaceholder: PropTypes.string
};

export default TaskCompletedDatePicker;
