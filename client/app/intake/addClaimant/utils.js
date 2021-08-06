import PropTypes from 'prop-types';

import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { camelCase, reduce, startCase } from 'lodash';

import ApiUtil from 'app/util/ApiUtil';

import { DOB_INVALID_ERRS } from 'app/../COPY';

const { AGE_MIN_ERR, AGE_MAX_ERR, FUTURE_ERR } = DOB_INVALID_ERRS;

const additionalFieldsRequired = (partyType, relationship) => {
  return ['individual', 'organization'].includes(partyType) || ['spouse', 'child'].includes(relationship);
};

const validateDOB = (date, age = null) => {
  const cutoff = new Date();

  if (!isNaN(age)) {
    cutoff.setFullYear(cutoff.getFullYear() - age);
  }

  /* if age is 118 (max), assert chosen date isn't greater than max.
    if age is 14, assert chosen date is before min */
  return age === 118 ? date > cutoff : date < cutoff;
};

export const schema = yup.object().shape({
  relationship: yup.string().required(),
  partyType: yup.string().when(['listedAttorney', 'relationship'], {
    is: (listedAttorney, relationship) =>
      listedAttorney?.value === 'not_listed' || relationship === 'other',
    then: yup.string().required(),
  }),
  firstName: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) =>
      partyType === 'individual' || ['spouse', 'child'].includes(relationship),
    then: yup.string().required(),
  }),
  middleName: yup.string(),
  lastName: yup.string(),
  suffix: yup.string(),
  dateOfBirth: yup.date().
    max(new Date(), FUTURE_ERR).
    test('age', AGE_MIN_ERR, (date) => validateDOB(date, 14)).
    test('age', AGE_MAX_ERR, (date) => validateDOB(date, 118)),
  name: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  addressLine1: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  addressLine2: yup.string(),
  addressLine3: yup.string(),
  city: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  state: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  zip: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.
      string().
      max(25),
  }),
  country: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string(),
  poaForm: yup.string().when(['relationship', '$hidePOAForm'], {
    is: (relationship, hidePOAForm) => relationship !== 'attorney' && !hidePOAForm,
    then: yup.string().required(),
  }),
  listedAttorney: yup.object().when(['relationship','$hideListedAttorney'], {
    is: (relationship, hideListedAttorney) => relationship === 'attorney' && !hideListedAttorney,
    then: yup.object().required(),
  }),
});

export const defaultFormValues = {
  relationship: null,
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
  state: null,
  zip: '',
  country: '',
  emailAddress: '',
  phoneNumber: '',
  poaForm: null,
  listedAttorney: null
};

export const useClaimantForm = ({ defaultValues = defaultFormValues } = {}, hidePOAForm = false, hideListedAttorney = false) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    context: { hidePOAForm, hideListedAttorney },
    mode: 'onChange',
    reValidateMode: 'onChange',
    defaultValues
  });

  return methods;
};

export const formatAddress = (bgsAddress) => {
  return reduce(
    bgsAddress,
    (result, value, key) => {
      result[key] = startCase(camelCase(value));
      if (['state', 'country'].includes(key)) {
        result[key] = value;
      } else {
        result[key] = startCase(camelCase(value));
      }

      return result;
    },
    {}
  );
};

export const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', {
    query: { query: search },
  });

  return res?.body;
};

export const claimantPropTypes = {
  partyType: PropTypes.oneOf(['individual', 'organization']),
  name: PropTypes.string,
  firstName: PropTypes.string,
  middleName: PropTypes.string,
  lastName: PropTypes.string,
  addressLine1: PropTypes.string,
  addressLine2: PropTypes.string,
  addressLine3: PropTypes.string,
  city: PropTypes.string,
  state: PropTypes.string,
  zip: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  country: PropTypes.string,
  emailAddress: PropTypes.string,
  phoneNumber: PropTypes.string,
};

export const poaPropTypes = {
  partyType: PropTypes.oneOf(['individual', 'organization']),
  name: PropTypes.string,
  firstName: PropTypes.string,
  middleName: PropTypes.string,
  lastName: PropTypes.string,
  addressLine1: PropTypes.string,
  addressLine2: PropTypes.string,
  addressLine3: PropTypes.string,
  city: PropTypes.string,
  state: PropTypes.string,
  zip: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  country: PropTypes.string,
  emailAddress: PropTypes.string,
  phoneNumber: PropTypes.string,
};
