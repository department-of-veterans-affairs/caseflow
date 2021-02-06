import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';

const dropdownOptSchema = yup.object().shape({
  label: yup.string().required(),
  value: yup.string().required(),
});

export const schema = yup.object().shape({
  relationship: dropdownOptSchema.required(),
  partyType: yup.string().when('relationship', {
  	is: 'other',
    then: yup.string().required()
  }).when('listedAttorney', {
    is: (value) => value?.value === 'not_listed',
    then: yup.string().required()
  }),
  firstName: yup.
    string().
    when('relationship', {
      is: 'child',
      then: yup.string().required(),
    }).
    when('relationship', {
      is: 'spouse',
      then: yup.string().required(),
    }).
    when('partyType', {
      is: 'individual',
      then: yup.string().required(),
    }),
  middleName: yup.string(),
  lastName: yup.string(),
  suffix: yup.string(),
  organization: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  address1: yup.string().when('partyType', {
	  is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required()
  }),
  address2: yup.string(),
  address3: yup.string(),
  city: yup.string().when('partyType', {
	  is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required()
  }),
  state: yup.object().when('partyType', {
	  is: (value) => ['individual', 'organization'].includes(value),
    then: dropdownOptSchema.required()
  }),
  zip: yup.number().when('partyType', {
	  is: (value) => ['individual', 'organization'].includes(value),
    then: yup.number().min(5).required()
  }),
  country: yup.string().when('partyType', {
	  is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required()
  }),
  email: yup.string().email(),
  phoneNumber: yup.string(),
  vaForm: yup.string().required(),
});

export const useAddClaimantForm = () => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    defaultValues: {},
  });

  return methods;
};
