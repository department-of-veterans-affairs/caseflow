import React, { useCallback, useEffect } from 'react';
import { Controller, useFormContext } from 'react-hook-form';
import { debounce } from 'lodash';
import PropTypes from 'prop-types';
import styled from 'styled-components';

import * as Constants from '../constants';
import { fetchAttorneys, formatAddress } from './utils';
import { ADD_CLAIMANT_PAGE_DESCRIPTION, ERROR_EMAIL_INVALID_FORMAT } from 'app/../COPY';

import Address from 'app/queue/components/Address';
import AddressForm from 'app/components/AddressForm';
import DateSelector from 'app/components/DateSelector';
import RadioField from 'app/components/RadioField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TextField from 'app/components/TextField';

const relationshipOpts = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'other', label: 'Other' },
];

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' },
];

const getAttorneyClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return [];
  }

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id,
    address: formatAddress(item.address),
  }));

  options.push({ label: 'Name not listed', value: 'not_listed' });

  return options;
};

// We'll show all items returned from the backend instead of using default substring matching
const filterOption = () => true;

export const ClaimantForm = ({
  onAttorneySearch = fetchAttorneys,
  onSubmit,
  dateOfBirthFieldToggle = true,
  ...props
}) => {
  const methods = useFormContext();
  const { control, register, watch, handleSubmit, setValue, errors } = methods;

  const emailValidationError = errors?.emailAddress && ERROR_EMAIL_INVALID_FORMAT;
  const dobValidationError = errors?.dateOfBirth && errors.dateOfBirth.message;

  const watchRelationship = watch('relationship');
  const dependentRelationship = ['spouse', 'child'].includes(watchRelationship);
  const watchPartyType = watch('partyType');
  const watchListedAttorney = watch('listedAttorney');
  const attorneyRelationship = watchRelationship === 'attorney';
  const attorneyNotListed = watchListedAttorney?.value === 'not_listed';
  const listedAttorney = attorneyRelationship && watchListedAttorney?.value && !attorneyNotListed;
  const showPartyType = watchRelationship === 'other' || (watchRelationship === 'attorney' && attorneyNotListed);
  const partyType = (showPartyType && watchPartyType) || (dependentRelationship && 'individual');

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getAttorneyClaimantOpts(search, onAttorneySearch).then((res) =>
        callback(res)
      );
    }, 250),
    [onAttorneySearch]
  );

  useEffect(() => {
    if (watchRelationship !== 'attorney') {
      setValue('listedAttorney', null);
    }
  }, [watchRelationship]);

  return (
    <>
      <h1>{props.editAppellantHeader || 'Add Claimant'}</h1>
      <p>{props.editAppellantDescription || ADD_CLAIMANT_PAGE_DESCRIPTION}</p>
      <form onSubmit={handleSubmit(onSubmit)}>
        {!props.POA && <Controller
          control={control}
          name="relationship"
          defaultValue={null}
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label="Relationship to the Veteran"
              options={relationshipOpts}
              onChange={(valObj) => {
                onChange(valObj.value);
              }}
              strongLabel
            />
          )}
        />}
        <br />
        {watchRelationship === 'attorney' && !props.hideListedAttorney && (
          <Controller
            control={control}
            name="listedAttorney"
            defaultValue={null}
            render={({ onChange, ...rest }) => (
              <FieldDiv>
                <SearchableDropdown
                  {...rest}
                  label={`${props.POA ? 'Representative' : 'Claimant'}'s name`}
                  filterOption={filterOption}
                  async={asyncFn}
                  defaultOptions
                  debounce={250}
                  strongLabel
                  isClearable
                  onChange={(valObj) => {
                    onChange(valObj);
                    setValue('listedAttorney', valObj);
                  }}
                  placeholder="Type to search..."
                />
              </FieldDiv>
            )}
          />
        )}

        {listedAttorney && watchListedAttorney?.address && (
          <div>
            <ClaimantAddress>
              <strong>{props.POA ? 'Representative' : 'Claimant'}'s address</strong>
            </ClaimantAddress>
            <br />
            <Address address={watchListedAttorney?.address} />
          </div>
        )}

        {showPartyType && (
          <RadioField
            name="partyType"
            label={`Is the ${props.POA ? 'representative' : 'claimant'} an organization or individual?`}
            inputRef={register}
            strongLabel
            vertical
            options={partyTypeOpts}
          />
        )}
        <br />
        {partyType === 'individual' && (
          <>
            <FieldDiv>
              <TextField
                name="firstName"
                label="First name"
                inputRef={register}
                strongLabel
              />
            </FieldDiv>
            <FieldDiv>
              <TextField
                name="middleName"
                label="Middle name/initial"
                inputRef={register}
                optional
                strongLabel
              />
            </FieldDiv>
            <FieldDiv>
              <TextField
                name="lastName"
                label="Last name"
                inputRef={register}
                optional
                strongLabel
              />
            </FieldDiv>
            <SuffixDOB>
              <TextField
                name="suffix"
                label="Suffix"
                inputRef={register}
                optional
                strongLabel
              />
              { dateOfBirthFieldToggle && !props.POA &&
                <DateSelector
                  optional
                  inputRef={register({
                    valueAsDate: true
                  })}
                  name="dateOfBirth"
                  label={<b>Date of birth</b>}
                  type="date"
                  validationError={dobValidationError}
                />
              }
            </SuffixDOB>
          </>
        )}
        {partyType === 'organization' && (
          <TextField
            name="name"
            label="Organization name"
            inputRef={register}
            strongLabel
          />
        )}
        {partyType && (
          <>
            <AddressForm {...methods} />
            <FieldDiv>
              <TextField
                validationError={emailValidationError}
                name="emailAddress"
                label="Claimant email"
                inputRef={register}
                optional
                strongLabel
              />
            </FieldDiv>
            <PhoneNumber>
              <TextField
                name="phoneNumber"
                label="Phone number"
                inputRef={register}
                optional
                strongLabel
              />
            </PhoneNumber>
          </>
        )}
        {(partyType && !attorneyRelationship && !props.hidePOAForm) && (
          <RadioField
            options={Constants.BOOLEAN_RADIO_OPTIONS}
            vertical
            inputRef={register}
            label="Do you have a VA Form 21-22 for this claimant?"
            name="poaForm"
            strongLabel
          />
        )}
      </form>
    </>
  );
};

ClaimantForm.propTypes = {
  onAttorneySearch: PropTypes.func,
  onBack: PropTypes.func,
  onSubmit: PropTypes.func,
  dateOfBirthFieldToggle: PropTypes.bool,
  editAppellantHeader: PropTypes.string,
  editAppellantDescription: PropTypes.string,
  hidePOAForm: PropTypes.bool,
  hideListedAttorney: PropTypes.bool,
  POA: PropTypes.bool
};

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

const SuffixDOB = styled.div`
  display: grid;
  grid-gap: 10px;
  grid-template-columns: 7.5em 19em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 1.5em;
`;

const ClaimantAddress = styled.div`
  margin-top: 1.5em;
`;
