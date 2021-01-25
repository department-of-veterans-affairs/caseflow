import { yupResolver } from '@hookform/resolvers';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';

const dropdownOptSchema = yup.object().shape({
  label: yup.string().required(),
  value: yup.string().required(),
});

export const schema = yup.object().shape({
  relationship: dropdownOptSchema.required(),
  partyType: yup.string().when('relationship', {
  	is: (value) => ['other', 'attorney'].includes(value),
    then: yup.string().required(),
  }),
  firstName: yup.string().when('relationship', {
	  is: 'child', then: yup.string().required()
  }).when('relationship', {
	  is: 'spouse', then: yup.string().required()
  }).when('partyType', {
	  is: 'individual', then: yup.string().required()
  }),
  middleName: yup.string(),
  lastName: yup.string(),
  suffix: yup.string(),
  organization: yup.string().when('partyType', {
  	is: 'organization', then: yup.string().required(),
  }),
  address1: yup.string().required(),
  address2: yup.string(),
  address3: yup.string(),
  city: yup.string().required(),
  state: dropdownOptSchema.required(),
  zip: yup.number().min(5).required(),
  country: yup.string().required(),
  email: yup.string().email(),
  phoneNumber: yup.string(),
  vaForm: yup.string().required()
});

export const useAddClaimantForm = () => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    defaultValues: {},
  });

  return methods;
};
