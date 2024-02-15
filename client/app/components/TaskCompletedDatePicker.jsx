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
      <div>
        <DateSelector onChange={props.handleTaskCompletedDateChange} label="from" type="date" />
        <DateSelector onChange={props.handleTaskCompletedSecondaryDateChange} label="to" type="date" />
      </div>);
    case taskCompletedDateFilterStates.BEFORE: return (
      <div>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} label="To" type="date" />
      </div>
    );
    case taskCompletedDateFilterStates.AFTER: return (
      <div>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} label="From" type="date" />
      </div>
    );
    case taskCompletedDateFilterStates.ON: return (
      <div>
        <DateSelector onChange={(value) => props.handleTaskCompletedDateChange(value)} label="On" type="date" />
      </div>
    );

    default:
    }
  };

  return <>
    <ReactSelectDropdown
      label="Date filter parameters"
      options={dateDropdownMap}
      onChangeMethod={props.onChangeMethod} />
    {getDatePickerElements()}
    <Button onClick={props.handleTaskCompletedApplyFilter}>Apply filter</Button>

  </>;
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
