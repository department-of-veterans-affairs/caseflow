import React, { useState } from 'react';
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
  const [isDateSelected, setDateSelected] = useState(false);
  const [isSecondaryDateSelected, setSecondaryDateSelected] = useState(false);
  const dateErrorsFrom = props.dateErrorsFrom;
  const dateErrorsTo = props.dateErrorsTo;

  const handleDateChange = (value) => {
    props.handleTaskCompletedDateChange(value);
    setDateSelected(Boolean(value));
  };

  const handleSecondaryDateChange = (value) => {
    props.handleTaskCompletedSecondaryDateChange(value);
    setSecondaryDateSelected(Boolean(value));
  };

  const handleApplyFilter = () => {
    props.handleTaskCompletedApplyFilter();
  };

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

  const taskCompletedDateFilterStates = props.taskCompletedDateFilterStates;
  const isApplyFilterButtonDisabled =
    props.taskCompletedDateState === taskCompletedDateFilterStates.BETWEEN ?
      !((isDateSelected && isSecondaryDateSelected) && (dateErrorsFrom.length <= 0 && dateErrorsTo.length <= 0)) :
      !(isDateSelected && dateErrorsFrom.length <= 0);

  const getDatePickerElements = () => {

    switch (props.taskCompletedDateState) {
    case taskCompletedDateFilterStates.BETWEEN: return (
      <div className="date-selectors-margin">
        <DateSelector
          onChange={handleDateChange}
          label="From"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')} />
        <DateSelector
          onChange={handleSecondaryDateChange}
          label="To"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsTo, 'toDate')} />
      </div>);
    case taskCompletedDateFilterStates.BEFORE: return (
      <div className="date-selectors-margin">
        <DateSelector
          onChange={handleDateChange}
          label="Date Completed"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')} />
      </div>
    );
    case taskCompletedDateFilterStates.AFTER: return (
      <div className="date-selectors-margin">
        <DateSelector
          onChange={handleDateChange}
          label="Date Completed"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')} />
      </div>
    );
    case taskCompletedDateFilterStates.ON: return (
      <div className="date-selectors-margin">
        <DateSelector
          onChange={handleDateChange}
          label="Date Completed"
          type="date"
          errorMessage={errorMessagesNode(dateErrorsFrom, 'fromDate')} />
      </div>
    );

    default:
    }
  };

  return <div id="dropdown" className="task-completed-date-picker-container">
    <div className="react-select-dropdown-div">
      <ReactSelectDropdown
        className="receipt-date opt-select"
        label="Date filter parameters"
        options={dateDropdownMap}
        onChangeMethod={props.onChangeMethod} />
    </div>

    <div className="date-picker-margin">
      {getDatePickerElements()}
    </div>
    <div className="apply-filter-div">
      <Button onClick={handleApplyFilter} disabled={isApplyFilterButtonDisabled}>Apply filter</Button>
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
  customPlaceholder: PropTypes.string,
  dateErrorsFrom: PropTypes.array,
  dateErrorsTo: PropTypes.array
};

export default TaskCompletedDatePicker;
