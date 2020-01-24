import React from 'react';

import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { withKnobs } from '@storybook/addon-knobs';
import TextField from '../../app/components/TextField';
import Button from '../../app/components/Button';

export default {
  title: 'Development/Form Management/React Hook Form',
  decorators: [withKnobs]
};

export const basic = () => {
  const validationSchema = yup.object().shape({
    name: yup.string().required(),
    email: yup.
      string().
      email().
      required()
  });

  const { register, handleSubmit, errors } = useForm({ validationSchema });
  const onSubmit = (data) => console.log(data);

  return (
    <form noValidate onSubmit={handleSubmit(onSubmit)}>
      <TextField ref={register} name="name" label="Name" required errorMessage={errors.name && errors.name.message} />
      <TextField
        ref={register}
        name="email"
        label="Email"
        required
        errorMessage={errors.email && errors.email.message}
      />

      <Button type="submit">Submit</Button>
    </form>
  );
};
