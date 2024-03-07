import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import { FORM_TYPES } from '../constants';
import * as yup from 'yup';

const sharedValidation = {
  listedAttorney: yup.object().required(),
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
  name: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  suffix: yup.string(),
  addressLine2: yup.string(),
  addressLine3: yup.string(),
  zip: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.
      string().
      max(25),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string()
};

export const schema = yup.object().shape({
  lastName: yup.string(),
  addressLine1: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  city: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  state: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  country: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  ...sharedValidation
});

export const schemaHlrOrSc = yup.object().shape({
  lastName: yup.string().when('partyType', {
    is: 'individual',
    then: yup.string().required(),
  }),
  addressLine1: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  city: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  state: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  country: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  ...sharedValidation
});

const defaultFormValues = {
  partyType: null,
  name: '',
  firstName: '',
  middleName: '',
  lastName: '',
  suffix: '',
  addressLine1: '',
  addressLine2: '',
  addressLine3: '',
  city: '',
  state: '',
  zip: '',
  country: '',
  emailAddress: '',
  phoneNumber: '',
  listedAttorney: null
};

export const useAddPoaForm = ({ defaultValues = {}, selectedForm = {} } = {}) => {
  const isHLROrSCForm = [
    FORM_TYPES.HIGHER_LEVEL_REVIEW.key,
    FORM_TYPES.SUPPLEMENTAL_CLAIM.key
  ].includes(selectedForm.key);

  const methods = useForm({
    resolver: isHLROrSCForm ? yupResolver(schemaHlrOrSc) : yupResolver(schema),
    mode: 'onChange',
    reValidateMode: 'onChange',
    defaultValues: { ...defaultValues, ...defaultFormValues },
  });

  return methods;
};
