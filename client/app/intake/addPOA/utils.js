import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';

export const schema = yup.object().shape({
  partyType: yup.string().when('listedAttorney', {
    is: (value) =>
      value?.value === 'not_listed',
    then: yup.string().required(),
  }),
  firstName: yup.string().when('partyType', {
    is: 'individual',
    then: yup.string().required(),
  }),
  middleName: yup.string(),
  lastName: yup.string(),
  suffix: yup.string(),
  name: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  addressLine1: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  addressLine2: yup.string(),
  addressLine3: yup.string(),
  city: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  state: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  zip: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.
      string().
      max(25),
  }),
  country: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string(),
});

export const useAddPoaForm = ({ defaultValues = {} } = {}) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    reValidateMode: 'onChange',
    defaultValues,
  });

  return methods;
};
