import { yupResolver } from '@hookform/resolvers';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';

const dropdownOptSchema = yup.object().shape({
  label: yup.string().required(),
  value: yup.string().required(),
});

export const schema = yup.object().shape({
  relationship: dropdownOptSchema.required(),
});

export const useAddClaimantForm = () => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  return methods;
};
