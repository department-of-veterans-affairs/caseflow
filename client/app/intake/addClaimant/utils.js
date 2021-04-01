import PropTypes from 'prop-types';

import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { camelCase, reduce, startCase } from 'lodash';

import ApiUtil from 'app/util/ApiUtil';

const additionalFieldsRequired = (partyType, relationship) => {
  return ['individual', 'organization'].includes(partyType) || ['spouse', 'child'].includes(relationship);
}

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
  zip: yup.number().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.
      number().
      min(5).
      required(),
  }),
  country: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string(),
  poaForm: yup.string().when('relationship', {
    is: (relationship) => relationship !== 'attorney',
    then: yup.string().required(),
  }),
  listedAttorney: yup.object().when('relationship', {
    is: 'attorney',
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

export const useAddClaimantForm = ({ defaultValues = defaultFormValues } = {}) => {
  const methods = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
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
