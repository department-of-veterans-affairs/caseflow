import React from 'react';
import DateSelector from 'app/components/DateSelector';
import { useFormContext } from 'react-hook-form';

const PriorDecisionDateSelector = () => {
  const { register, errors } = useFormContext();

  return <DateSelector
    label="Decision date"
    name="decisionDate"
    inputRef={register}
    errorMessage={errors.decisionDate?.message}
    type="date" />;
};

export default PriorDecisionDateSelector;
