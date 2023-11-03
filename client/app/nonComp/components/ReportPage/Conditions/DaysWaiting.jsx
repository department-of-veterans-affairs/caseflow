import React from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import NumberField from 'app/components/NumberField';
import styled from 'styled-components';

import { Controller, useFormContext } from 'react-hook-form';

const WidthDiv = styled.div`
  max-width: 45%;
  width: 100%
`;

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

  const displayValueOne = getValues(dropdownName);

  const displayValueTwo = getValues(dropdownName) === 'between';

  const valueOneLabel = displayValueTwo ? 'Min days' : 'Number of days';

  const valueTwoContent = () => {
    return <>
      to
      <NumberField
        label="Max days"
        name={valueTwoName}
        inputRef={register}
        isInteger
        onChange={(value) => {
          setValue(valueTwoName, value);

          return value;
        }}
      />
    </>;
  };

  return <div className="days-waiting">
    <WidthDiv>
      <Controller
        control={control}
        name={dropdownName}
        defaultValue={null}
        render={({ onChange, ...rest }) => (
          <SearchableDropdown
            {...rest}
            label="Time Range"
            options={options}
            onChange={(valObj) => {
              setValue(valueOneName, null);
              setValue(valueTwoName, null);
              onChange(valObj?.value);
            }}
          />
        )}
      />
    </WidthDiv>
    {displayValueOne ?
      <NumberField
        label={valueOneLabel}
        name={valueOneName}
        inputRef={register}
        isInteger
        onChange={(value) => {
          setValue(valueOneName, value);

          return value;
        }}
      /> : null}
    {displayValueTwo ?
      valueTwoContent() : null}

  </div>;
};
