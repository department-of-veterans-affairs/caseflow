import React, { useCallback } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { Controller } from 'react-hook-form';
import _, { debounce } from 'lodash';

import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';

import Address from 'app/queue/components/Address';
import AddressForm from 'app/components/AddressForm';
import RadioField from 'app/components/RadioField';
import SearchableDropdown from 'app/components/SearchableDropdown';
import TextField from 'app/components/TextField';
import { useAddClaimantForm } from './utils';

const firstName = css({
  marginBottom: '1.5em',
});

const suffix = css({
  maxWidth: '8em',
});

const phoneNumber = css({
  width: '240px',
  marginBottom: '2em'
});

const field = css({
  marginBottom: '0.5em'
});

const partyTypeOpts = [
  { displayText: 'Organization', value: 'organization', ariaLabel: 'Organization' },
  { displayText: 'Individual', value: 'individual', ariaLabel: 'Individual' }
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

export const AddClaimantPage = ({ onSubmit, methods }) => {
  const { control, handleSubmit, watch, register } = methods || useAddClaimantForm();
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
      }

      { listedAttorney?.address &&
        <div>
          <strong>Claimant's address</strong>
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
        <div aria-label="nameFields">
          <TextField
            name="firstName"
            label="First name"
            inputRef={register}
            strongLabel
            inputStyling={firstName}
          />
          <TextField
            name="middleName"
            label="Middle name/initial"
            inputRef={register}
            optional
            strongLabel
            inputStyling={field}
          />
          <TextField
            name="lastName"
            label="Last name"
            inputRef={register}
            optional
            strongLabel
            inputStyling={field}
          />
          <div {...suffix}>
            <TextField
              name="suffix"
              label="Suffix"
              inputRef={register}
              optional
              strongLabel
            />
          </div>
        </div>
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
        <div aria-label="additionalFields">
          <AddressForm watch={watch} control={control} register={register} />
          <TextField
            name="email"
            label="Claimant email"
            inputRef={register}
            optional
            strongLabel
            inputStyling={field}
          />
          <div {...phoneNumber}>
            <TextField
              name="phoneNumber"
              label="Phone number"
              inputRef={register}
              optional
              strongLabel
            />
          </div>
        </div>
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

AddClaimantPage.propTypes = {
  onSubmit: PropTypes.func,
  methods: PropTypes.object
};

export default AddClaimantPage;
