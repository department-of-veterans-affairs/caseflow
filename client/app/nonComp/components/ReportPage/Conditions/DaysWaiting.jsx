import React from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import NumberField from 'app/components/NumberField';
import styled from 'styled-components';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';
import DAYS_WAITING_CONDITION_OPTIONS from 'constants/DAYS_WAITING_CONDITION_OPTIONS';

const WidthDiv = styled.div`
  max-width: 45%;
  width: 100%
`;

export const DaysWaiting = ({ control, register, name, field, errors }) => {
  const dropdownName = `${name}.options.comparisonOperator`;
  const valueOneName = `${name}.options.valueOne`;
  const valueTwoName = `${name}.options.valueTwo`;

  const { setValue, formState } = useFormContext();

  const displayValueOne = field.options.comparisonOperator;

  const displayValueTwo = field.options.comparisonOperator === 'between';

  const valueOneLabel = displayValueTwo ? 'Min days' : 'Number of days';

  return <div className="days-waiting">
    <WidthDiv>
      <Controller
        control={control}
        name={dropdownName}
        defaultValue={field.options.comparisonOperator ?? ''}
        render={({ onChange, ...rest }) => (
          <SearchableDropdown
            {...rest}
            label="Time Range"
            options={DAYS_WAITING_CONDITION_OPTIONS}
            errorMessage={errors?.options?.comparisonOperator?.message ?? ''}
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
        defaultValue={field.options.valueOne}
        inputRef={register}
        isInteger
        errorMessage={errors?.options?.valueOne?.message ?? ''}
        onChange={(value) => {
          setValue(valueOneName, value);
        }}
      /> : null}
    {displayValueTwo ?
      <>
      to
        <NumberField
          label="Max days"
          name={valueTwoName}
          defaultValue={field.options.valueTwo}
          inputRef={register}
          isInteger
          errorMessage={errors?.options?.valueTwo?.message ?? ''}
          onChange={(value) => {
            setValue(valueTwoName, value);
          }}
        />
      </> : null}

  </div>;
};

DaysWaiting.propTypes = {
  control: PropTypes.object,
  register: PropTypes.func,
  name: PropTypes.string,
  field: PropTypes.object,
  errors: PropTypes.object
};
