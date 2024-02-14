import React, { useState } from 'react';
import ReactSelectDropdown from '../../../client/app/components/ReactSelectDropdown';
import DateSelector from './DateSelector';
import Button from './Button';

const dateDropdownMap = [
  { value: 0, label: 'Between these dates' },
  { value: 1, label: 'Before this date' },
  { value: 2, label: 'After this date' },
  { value: 3, label: 'On this date' }
];

const receiptDateFilterStates = {
  UNINITIALIZED: '',
  BETWEEN: 0,
  BEFORE: 1,
  AFTER: 2,
  ON: 3
};

const RecieptDatePicker = (props) => {
  const [dateOption, setDateOption] = useState(-1);
  const handleDateChange = (value) => {
    setDateOption(value);
  }
  const getDatePickerElements = () => {
    switch (props.receiptDateState) {
    case receiptDateFilterStates.BETWEEN: return (
      <div>
        <DateSelector label="from" type="date" />
        <DateSelector label="to" type="date" />
      </div>);
    case receiptDateFilterStates.BEFORE: return (
      <div>
        <DateSelector onChange={(value) => handleDateChange(value)} label="To" type="date" />
      </div>
    );
    case receiptDateFilterStates.AFTER: return (
      <div>
        <DateSelector onChange={(value) => handleDateChange(value)} label="From" type="date" />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div>
        <DateSelector onChange={(value) => handleDateChange(value)} label="On" type="date" />
      </div>
    );

    default:
    }
  };

  return <>
    <ReactSelectDropdown label={'Date filter parameters'} options={dateDropdownMap} onChangeMethod={props.onChangeMethod} />
    {getDatePickerElements()}
    <Button onClick={() => props.setSelectedValue([props.receiptDateState, dateOption], "vaDor")}>Apply filter</Button>
  </>;
};

export default RecieptDatePicker;
