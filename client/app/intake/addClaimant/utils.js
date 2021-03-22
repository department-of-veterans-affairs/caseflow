import PropTypes from 'prop-types';

import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { camelCase, reduce, startCase } from 'lodash';

import ApiUtil from 'app/util/ApiUtil';

export const schema = yup.object().shape({
  relationship: yup.string().required(),
  partyType: yup.
    string().
    when('relationship', {
      is: 'other',
      then: yup.string().required(),
    }).
    when('listedAttorney', {
      is: (value) => value?.value === 'not_listed',
      then: yup.string().required(),
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
  zip: yup.number().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.
      number().
      min(5).
      required(),
  }),
  country: yup.string().when('partyType', {
    is: (value) => ['individual', 'organization'].includes(value),
    then: yup.string().required(),
  }),
  emailAddress: yup.string().emailAddress(),
  phoneNumber: yup.string(),
  poaForm: yup.string().required(),
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
};

export const useAddClaimantForm = ({ defaultValues = defaultFormValues } = {}) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
    defaultValues,
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
