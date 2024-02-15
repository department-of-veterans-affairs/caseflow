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

const receiptDatePicker = (props) => {
  const getDatePickerElements = () => {
    const receiptDateFilterStates = props.receiptDateFilterStates;

    switch (props.receiptDateState) {
    case receiptDateFilterStates.BETWEEN: return (
      <div>
        <DateSelector onChange={props.handleDateChange} label="from" type="date" />
        <DateSelector onChange={props.handleSecondaryDateChange} label="to" type="date" />
      </div>);
    case receiptDateFilterStates.BEFORE: return (
      <div>
        <DateSelector onChange={(value) => props.handleDateChange(value)} label="To" type="date" />
      </div>
    );
    case receiptDateFilterStates.AFTER: return (
      <div>
        <DateSelector onChange={(value) => props.handleDateChange(value)} label="From" type="date" />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div>
        <DateSelector onChange={(value) => props.handleDateChange(value)} label="On" type="date" />
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
    <Button onClick={props.handleApplyFilter}>Apply filter</Button>

  </>;
};

receiptDatePicker.propTypes = {
  receiptDateFilterStates: PropTypes.object,
  receiptDateState: PropTypes.number,
  handleApplyFilter: PropTypes.func.isRequired,
  handleDateChange: PropTypes.func.isRequired,
  handleSecondaryDateChange: PropTypes.func.isRequired,
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

export default receiptDatePicker;
