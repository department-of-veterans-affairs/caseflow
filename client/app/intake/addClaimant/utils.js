import PropTypes from 'prop-types';

import { yupResolver } from '@hookform/resolvers/yup';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { sub } from 'date-fns';
import { camelCase, reduce, startCase } from 'lodash';
import { FORM_TYPES } from '../constants';

import ApiUtil from 'app/util/ApiUtil';
import { DOB_INVALID_ERRS, SSN_INVALID_ERR, EIN_INVALID_ERR } from 'app/../COPY';

const { AGE_MIN_ERR, AGE_MAX_ERR } = DOB_INVALID_ERRS;

const additionalFieldsRequired = (partyType, relationship) => {
  return ['individual', 'organization'].includes(partyType) || ['spouse', 'child'].includes(relationship);
};

const yearsFromToday = (years) => {
  return sub(new Date(), { years });
};

const ssnRegex = /^(?!000|666)[0-9]{3}([ -]?)(?!00)[0-9]{2}\1(?!0000)[0-9]{4}$/gm;
const einRegex = /^(?!00)[0-9]{2}([ -]?)(?!0000000)[0-9]{7}$/gm;

const sharedValidation = {
  relationship: yup.string().when(['$hideListedAttorney'], {
    is: (hideListedAttorney) => !hideListedAttorney,
    then: yup.string().required(),
  }),
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
  suffix: yup.string(),
  dateOfBirth: yup.date().
    nullable().
    max(yearsFromToday(14), AGE_MIN_ERR).
    min(yearsFromToday(118), AGE_MAX_ERR),
  name: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  addressLine2: yup.string(),
  addressLine3: yup.string(),
  zip: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.
      string().
      max(25),
  }),
  emailAddress: yup.string().email(),
  phoneNumber: yup.string(),
  poaForm: yup.string().when(['relationship', '$hidePOAForm'], {
    is: (relationship, hidePOAForm) => relationship !== 'attorney' && !hidePOAForm,
    then: yup.string().required(),
  }),
  listedAttorney: yup.object().when(['relationship', '$hideListedAttorney'], {
    is: (relationship, hideListedAttorney) => (relationship === 'attorney' && !hideListedAttorney),
    then: yup.object().required(),
  }),
};

export const schema = yup.object().shape({
  lastName: yup.string(),
  addressLine1: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  city: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  state: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  country: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => additionalFieldsRequired(partyType, relationship),
    then: yup.string().required(),
  }),
  ...sharedValidation
});

export const schemaHLR = yup.object().shape({
  lastName: yup.string().when(['partyType', 'relationship'], {
    is: (partyType, relationship) => partyType === 'individual' || ['spouse', 'child'].includes(relationship),
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
  state: yup.string().nullable().
    when('partyType', {
      is: 'organization',
      then: yup.string().required(),
    }),
  country: yup.string().when('partyType', {
    is: 'organization',
    then: yup.string().required(),
  }),
  ssn: yup.string().
    matches(
      ssnRegex,
      {
        message: SSN_INVALID_ERR,
        excludeEmptyString: true
      }
  ),
  ein: yup.string().
    matches(
      einRegex,
      {
        message: EIN_INVALID_ERR,
        excludeEmptyString: true
      }
    ),
  ...sharedValidation,
});

export const defaultFormValues = {
  relationship: null,
  partyType: null,
  name: '',
  ein: '',
  firstName: '',
  middleName: '',
  lastName: '',
  suffix: '',
  ssn: '',
  dateOfBirth: null,
  addressLine1: '',
  addressLine2: '',
  addressLine3: '',
  city: '',
  state: '',
  zip: '',
  country: '',
  emailAddress: '',
  phoneNumber: '',
  poaForm: null,
  listedAttorney: null
};

export const useClaimantForm = (
  { defaultValues = {}, selectedForm = {} } = {},
  hidePOAForm = false,
  hideListedAttorney = false
) => {
  const isHLROrSCForm = [
    FORM_TYPES.HIGHER_LEVEL_REVIEW.key,
    FORM_TYPES.SUPPLEMENTAL_CLAIM.key
  ].includes(selectedForm.key);

  const methods = useForm({
    resolver: isHLROrSCForm ? yupResolver(schemaHLR) : yupResolver(schema),
    context: { hidePOAForm, hideListedAttorney },
    mode: 'onChange',
    reValidateMode: 'onChange',
    defaultValues: { ...defaultFormValues,
      ...defaultValues }
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
