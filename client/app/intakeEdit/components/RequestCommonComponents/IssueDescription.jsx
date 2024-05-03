import React from 'react';
import { useFormContext } from 'react-hook-form';
import TextField from 'app/components/TextField';

const IssueDescription = () => {
  const { register, errors } = useFormContext();

  return <TextField
    label="Issue description"
    name="decisionText"
    inputRef={register}
    errorMessage={errors.decisionText?.message}
  />;
};

export default IssueDescription;
