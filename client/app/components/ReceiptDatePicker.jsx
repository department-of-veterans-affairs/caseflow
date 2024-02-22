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
      <div style={{ marginLeft: '5%', marginRight: '5%' }}>
        <DateSelector
          onChange={props.handleDateChange}
          label="From"
          type="date" />
        <DateSelector
          onChange={props.handleSecondaryDateChange}
          label="To"
          type="date" />
      </div>);
    case receiptDateFilterStates.BEFORE: return (
      <div style={{ marginLeft: '5%', marginRight: '5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          type="date" />
      </div>
    );
    case receiptDateFilterStates.AFTER: return (
      <div style={{ marginLeft: '5%', marginRight: '5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          type="date" />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div style={{ marginLeft: '5%', marginRight: '5%' }}>
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          type="date" />
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
        onChangeMethod={props.onChangeMethod}
      />
    </div>
    <div style={{ width: '100%', margin: 'auto' }}>
      {getDatePickerElements()}
    </div>

    <div style={{ display: 'flex', margin: '10px 0px', justifyContent: 'center', width: '190px' }}>
      <Button disabled={props.isApplyButtonEnabled} onClick={props.handleApplyFilter}>
        <span>Apply Filter</span>
      </Button>
    </div>

  </div>;
};

receiptDatePicker.propTypes = {
  receiptDateFilterStates: PropTypes.object,
  receiptDateState: PropTypes.number,
  handleApplyFilter: PropTypes.func.isRequired,
  handleDateChange: PropTypes.func.isRequired,
  handleSecondaryDateChange: PropTypes.func.isRequired,
  isApplyButtonEnabled: PropTypes.bool.isRequired,
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
