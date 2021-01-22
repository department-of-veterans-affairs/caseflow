import { yupResolver } from '@hookform/resolvers';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';

const dropdownOptSchema = yup.object().shape({
  label: yup.string().required(),
  value: yup.string().required(),
});

const radioOptSchema = yup.object().shape({
	displayText: yup.string().required(),
	value: yup.string().required(),
});


export const schema = yup.object().shape({
  relationship: dropdownOptSchema.required(),
  // firstName: yup.string().when('relationship', {
  // 	  is: 'child', then: yup.string().required()
  //   }).when('relationship', {
  // 	  is: 'spouse', then: yup.string().required()
  //   }).when('type', {
  // 	  is: 'individual', then: yup.string().required()
  //   }),
  // middleName: yup.string(),
  // lastName: yup.string(), 
  // suffix: yup.string(),
  // email: yup.string().email(),
  // phoneNumber: yup.string(),
  vaForm: radioOptSchema.required(),
  // type: radioOptSchema.when('relationship', {
  // 	is: 'other', then: radioOptSchema.required(),
  // }),
  // organization: yup.string().when('type', {
  // 	is: 'organization', then: yup.string().required(),
  // }),
  // address1: yup.string().required()
  // address2: yup.string(),
  // address3: yup.string().when('type', {
  // 	is: 'organization', then: yup.string().required(),
  // }),
  // city: yup.string().required(),
  // state: dropdownOptSchema.required(),
  // zip: yup.number().required(),
  // country: yup.string().required(),
});

export const useAddClaimantForm = () => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });

  return methods;
};
