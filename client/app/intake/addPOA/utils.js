import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import { FORM_TYPES } from '../constants';
import * as yup from 'yup';

const sharedValidation = {

};

export const schema = yup.object().shape({
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

export const schemaHlrOrSc = yup.object().shape({
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
  lastName: yup.string().when('partyType', {
    is: 'individual',
    then: yup.string().required(),
  }),
  suffix: yup.string(),
  name: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  addressLine1: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  addressLine2: yup.string(),
  addressLine3: yup.string(),
  city: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  state: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  zip: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.
      string().
      max(25),
  }),
  country: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string(),
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
