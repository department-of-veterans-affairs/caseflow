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

  const errorMessagesNode = (errors, errType) => {
    if (errors.length) {
      return (
        errors.map((error, index) =>
          (errType === error.key) &&
            <p id={`${errType}Err${index}`} key={index} className="error-msg">
              {error.message}
            </p>
        )
      );
    }
  };

  const getDatePickerElements = () => {
    const receiptDateFilterStates = props.receiptDateFilterStates;
    const dateErrorsFrom = props.dateErrorsFrom;
    const dateErrorsTo = props.dateErrorsTo;

    switch (props.receiptDateState) {
    case receiptDateFilterStates.BETWEEN: return (
      <div className="date-pickers-margin">
        <DateSelector
          onChange={props.handleDateChange}
          label="From"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
        <DateSelector
          onChange={props.handleSecondaryDateChange}
          label="To"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsTo, 'toDate')}
        />
      </div>);
    case receiptDateFilterStates.BEFORE: return (
      <div className="date-pickers-margin">
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );
    case receiptDateFilterStates.AFTER: return (
      <div className="date-pickers-margin">
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div className="date-pickers-margin">
        <DateSelector
          onChange={(value) => props.handleDateChange(value)}
          label = "Receipt date"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')}
        />
      </div>
    );

    default:
    }
  };

  return <div id="dropdown" className="receipt-date-picker-container">
    <div className="receipt-date-dropdown-div">
      <ReactSelectDropdown
        className="receipt-date opt-select"
        label="Date filter parameters"
        options={dateDropdownMap}
        onChangeMethod={props.onChangeMethod}
      />
    </div>
    <div className="date-pickers-div">
      {getDatePickerElements()}
    </div>

    <div className="apply-filter-div">
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
  customPlaceholder: PropTypes.string,
  dateErrorsFrom: PropTypes.array,
  dateErrorsTo: PropTypes.array
};

export default receiptDatePicker;
