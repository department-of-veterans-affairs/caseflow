import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import styled from 'styled-components';
import { Controller } from 'react-hook-form';
import _, { debounce } from 'lodash';

import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

import Address from 'app/queue/components/Address';
import AddressForm from 'app/components/AddressForm';
import RadioField from 'app/components/RadioField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TextField from 'app/components/TextField';

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization' },
  { displayText: 'Individual', value: 'individual' }
];

const relationshipOpts = [
  { label: 'Attorney (previously or currently)', value: 'attorney' },
  { label: 'Child', value: 'child' },
  { label: 'Spouse', value: 'spouse' },
  { label: 'Other', value: 'other' },
];

const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', {
    query: { query: search }
  });

  return res?.body;
};

// We'll show all items returned from the backend instead of using default substring matching
const filterOption = () => true;

const getAttorneyClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return [];
  }

  const formatAddress = (bgsAddress) => {
    return _.reduce(bgsAddress, (result, value, key) => {
      result[key] = _.startCase(_.camelCase(value));
      if (['state', 'country'].includes(key)) {
        result[key] = value;
      } else {
        result[key] = _.startCase(_.camelCase(value));
      }

      return result;
    }, {});
  };

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id,
    address: formatAddress(item.address),
  }));

  options.push({ label: 'Name not listed', value: 'not_listed' });

  return options;
};

export const AddClaimantForm = ({ onSubmit, methods }) => {
  const { control, handleSubmit, watch, register } = methods;
  const watchRelationship = watch('relationship')?.value; /* set in SearchableDropdown */
  const listedAttorney = watch('listedAttorney');
  const attorneyNotListed = listedAttorney?.value === 'not_listed';
  const showPartyType = watchRelationship === 'other' || attorneyNotListed;
  const watchPartyType = watch('partyType');
  const showIndividualNameFields = watchPartyType === 'individual' || ['spouse', 'child'].includes(watchRelationship);
  const showAdditionalFields = watchPartyType || ['spouse', 'child'].includes(watchRelationship);

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getAttorneyClaimantOpts(search, fetchAttorneys).then((res) => callback(res));
    }, 250),
    [fetchAttorneys]
  );

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Controller
        control={control}
        name="relationship"
        label="Relationship to the Veteran"
        options={relationshipOpts}
        strongLabel
        as={SearchableDropdown}
      />
      <br />
      { watchRelationship === 'attorney' &&
        <>
          <Controller
            control={control}
            name="listedAttorney"
            defaultValue={null}
            render={({ ...rest }) => (
              <SearchableDropdown
                {...rest}
                label="Claimant's name"
                filterOption={filterOption}
                async={asyncFn}
                defaultOptions
                debounce={250}
                strongLabel
                isClearable
                placeholder="Type to search..."
              />
            )}
          />
        </>
      }

      { listedAttorney?.address &&
        <div>
          <ClaimantAddress>
            <strong>Claimant's address</strong>
          </ClaimantAddress>
          <br />
          <Address address={listedAttorney?.address} />
        </div>
      }

      { showPartyType &&
        <RadioField
          name="partyType"
          label="Is the claimant an organization or individual?"
          inputRef={register}
          strongLabel
          vertical
          options={partyTypeOpts}
        />
      }
      <br />
      { showIndividualNameFields &&
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
          <Suffix>
            <TextField
              name="suffix"
              label="Suffix"
              inputRef={register}
              optional
              strongLabel
            />
          </Suffix>
        </>
      }
      { watchPartyType === 'organization' &&
        <TextField
          name="organization"
          label="Organization name"
          inputRef={register}
          strongLabel
        />
      }
      { showAdditionalFields &&
        <>
          <AddressForm {...methods} />
          <FieldDiv>
            <TextField
              name="email"
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
      }
      { (showAdditionalFields || listedAttorney) &&
        <RadioField
          options={Constants.BOOLEAN_RADIO_OPTIONS}
          vertical
          inputRef={register}
          label="Do you have a VA Form 21-22 for this claimant?"
          name="vaForm"
          strongLabel
        />
      }
    </form>
  );
};

AddClaimantForm.propTypes = {
  onSubmit: PropTypes.func,
  methods: PropTypes.object
};

const FieldDiv = styled.div`
  margin-bottom: 1.5em;
`;

const Suffix = styled.div`
  max-width: 8em;
`;

const PhoneNumber = styled.div`
  width: 240px;
  margin-bottom: 2em;
`;

const ClaimantAddress = styled.div`
  margin-top: 1.5em;
`;

export default AddClaimantForm;
