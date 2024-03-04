import React from 'react';
import SearchableDropdown from 'app/components/SearchableDropdown';
import NumberField from 'app/components/NumberField';
import styled from 'styled-components';
import PropTypes from 'prop-types';
import * as yup from 'yup';

import { Controller, useFormContext } from 'react-hook-form';
import DAYS_WAITING_CONDITION_OPTIONS from 'constants/DAYS_WAITING_CONDITION_OPTIONS';
import * as ERRORS from 'constants/REPORT_PAGE_VALIDATION_ERRORS';
import { get } from 'lodash';

const WidthDiv = styled.div`
  max-width: 45%;
  width: 100%
`;

export const daysWaitingSchema = yup.object({
  comparisonOperator: yup.string().
    oneOf(DAYS_WAITING_CONDITION_OPTIONS.map((cond) => cond.value), ERRORS.MISSING_TIME_RANGE),
  valueOne: yup.number().typeError(ERRORS.MISSING_NUMBER).
    required(ERRORS.MISSING_NUMBER),
  valueTwo: yup.number().label('Max days').
    when('comparisonOperator', {
      is: 'between',
      then: (schema) => schema.typeError(ERRORS.MISSING_NUMBER).
        moreThan(yup.ref('valueOne'), ERRORS.MAX_DAYS_TOO_SMALL).
        required(ERRORS.MISSING_NUMBER),
      otherwise: (schema) => schema.notRequired()
    })
});

export const DaysWaiting = ({ control, register, name, field }) => {
  const dropdownName = `${name}.options.comparisonOperator`;
  const valueOneName = `${name}.options.valueOne`;
  const valueTwoName = `${name}.options.valueTwo`;

  const { setValue, errors } = useFormContext();

  const displayValueOne = field.options.comparisonOperator;

  const displayValueTwo = field.options.comparisonOperator === 'between';

  const valueOneLabel = displayValueTwo ? 'Min days' : 'Number of days';

  return <div className="days-waiting">
    <WidthDiv>
      <Controller
        control={control}
        name={dropdownName}
        defaultValue={field.options.comparisonOperator ?? ''}
        render={({ onChange, ref, ...rest }) => (
          <SearchableDropdown
            {...rest}
            label="Time Range"
            options={DAYS_WAITING_CONDITION_OPTIONS}
            inputRef={ref}
            errorMessage={get(errors, dropdownName)?.message}
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
        errorMessage={get(errors, valueOneName)?.message}
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
          errorMessage={get(errors, valueTwoName)?.message}
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
