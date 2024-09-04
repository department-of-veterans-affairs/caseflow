import React from 'react';
import { useFormContext } from 'react-hook-form';
import TextField from 'app/components/TextField';

const IssueDescription = () => {
  const { register } = useFormContext();

  return <TextField
    label="Issue description"
    name="nonratingIssueDescription"
    inputRef={register}
  />;
};

export default IssueDescription;
