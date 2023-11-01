import React from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import NumberField from 'app/components/NumberField';

import { Controller, useFormContext } from 'react-hook-form';

export const DaysWaiting = ({ control, register, name }) => {

  const options = [
    { label: 'Less than',
      value: 'lessThan' },
    { label: 'More than',
      value: 'moreThan' },
    { label: 'Equal to',
      value: 'equalTo' },
    { label: 'Between',
      value: 'between' }
  ];

  const dropdownName = `${name}.options.comparisonOperator`;
  const valueOneName = `${name}.options.valueOne`;
  const valueTwoName = `${name}.options.valueTwo`;

  const { setValue, getValues } = useFormContext();

  console.log(getValues(dropdownName));
  const displayValueOne = getValues(dropdownName); // display if any value is selected from comparison operator dropdown

  const displayValueTwo = getValues(dropdownName) === 'between'; // display only if between is selected

  const valueOneLabel = displayValueTwo ? 'Min days' : 'Number of days';

  return <div>
    <Controller
      control={control}
      name={dropdownName}
      defaultValue={null}
      // eslint-disable-next-line no-unused-vars
      render={({ onChange, ...rest }) => (
        <SearchableDropdown
          {...rest}
          label="Time Range"
          options={options}
          onChange={(valObj) => {
            onChange(valObj?.value);
          }}
          // placeholder="Select a variable"
        />
      )}
    />

    {displayValueOne &&
    <NumberField
      label={valueOneLabel}
      name={valueOneName}
      inputRef={register}
      isInteger
      // value={this.state.value}
      onChange={(value) => {
        setValue(valueOneName, value);

        return value;
      }}
    />}

    {displayValueTwo &&
    <NumberField
      label="Max days"
      name={valueTwoName}
      inputRef={register}
      isInteger
      // value={this.state.value}
      onChange={(value) => {
        setValue(valueTwoName, value);

        return value;
      }}
    />}
  </div>;
};
