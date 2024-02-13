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
  TO: 1,
  FROM: 2,
  ON: 3
};

const RecieptDatePicker = (props) => {
  const [dateOption, setDateOption] = useState(-1);

  const getDatePickerElements = () => {
    switch (dateOption) {
    case receiptDateFilterStates.BETWEEN: return (
      <div>
        <DateSelector label="from" type="date" />
        <DateSelector label="to" type="date" />
      </div>);
    case receiptDateFilterStates.TO: return (
      <div>
        <DateSelector label="To" type="date" />
      </div>
    );
    case receiptDateFilterStates.FROM: return (
      <div>
        <DateSelector label="From" type="date" />
      </div>
    );
    case receiptDateFilterStates.ON: return (
      <div>
        <DateSelector label="On" type="date" />
      </div>
    );

    default:
    }
  };
  const updateDateOption = (value) => {
    setDateOption(value.value);
    props.setSelectedValue("testVal", "vaDor");
  };

  return <>
    <ReactSelectDropdown label={'Date filter parameters'} options={dateDropdownMap} onChangeMethod={updateDateOption} />
    {getDatePickerElements()}
    <Button>Apply filter</Button>
  </>;
};

export default RecieptDatePicker;
