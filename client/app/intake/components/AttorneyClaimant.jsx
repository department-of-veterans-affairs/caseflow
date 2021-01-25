import React, { useState, useMemo, useCallback, useEffect } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';
import Modal from '../../components/Modal';
import {
  ADD_CLAIMANT_MODAL_TITLE,
  ADD_CLAIMANT_MODAL_DESCRIPTION
} from '../../../COPY';
import ReactMarkdown from 'react-markdown';
import SearchableDropdown from '../../components/SearchableDropdown';
import ApiUtil from '../../util/ApiUtil';
import Checkbox from '../../components/Checkbox';
import TextareaField from '../../components/TextareaField';

const fetchAttorneys = async (search = '') => {
  const res = await ApiUtil.get('/intake/attorneys', {
    query: { query: search }
  });

  return res?.body;
};
const getClaimantOpts = async (search = '', asyncFn) => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  if (search.length < 3) {
    return [];
  }

  const res = await asyncFn(search);
  const options = res.map((item) => ({
    label: item.name,
    value: item.participant_id,
  }));

  return options;
};
// We'll show all items returned from the backend instead of using default substring matching
const filterOption = () => true;

export const AttorneyClaimant = ({
  onCancel,
  onSubmit,
  onSearch = fetchAttorneys,
}) => {
  const [claimant, setClaimant] = useState(null);
  const [unlistedClaimant, setUnlistedClaimant] = useState(false);
  const isInvalid = useMemo(() => {
    return (
      (!unlistedClaimant && !claimant) || (unlistedClaimant)
    );
  }, [claimant, unlistedClaimant]);

  const handleChangeClaimant = (value) => setClaimant(value);
  const handleNotListed = (value) => setUnlistedClaimant(value);

  const asyncFn = useCallback(
    debounce((search, callback) => {
      getClaimantOpts(search, onSearch).then((res) => callback(res));
    }, 250),
    [onSearch]
  );

  useEffect(() => {
    if (!unlistedClaimant) {
      setClaimantNotes('');
    }
  }, [unlistedClaimant]);

  return (
      <div>
        <ReactMarkdown source={ADD_CLAIMANT_MODAL_DESCRIPTION} />
      </div>
      <SearchableDropdown
        name="claimant"
        label="Claimant's name"
        onChange={handleChangeClaimant}
        value={claimant}
        filterOption={filterOption}
        async={asyncFn}
        defaultOptions
        readOnly={unlistedClaimant}
        debounce={250}
        strongLabel
        isClearable
        placeholder="Type to search..."
      />

      {ALLOW_UNLISTED_CLAIMANTS && (
        <Checkbox
          label="Claimant not listed"
          name="notListed"
          onChange={handleNotListed}
          value={unlistedClaimant}
        />
      )}
      {unlistedClaimant && (
        <TextareaField
          label={
            <span>
              <b>Notes</b> e.g. claimant's name, address, law firm
            </span>
          }
          name="notes"
          value={claimantNotes}
          onChange={handleClaimantNotes}
        />
      )}
  );
};

AttorneyClaimant.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  onSearch: PropTypes.func,
  readOnly: PropTypes.bool,
};
