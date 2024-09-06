/* eslint-disable max-lines, max-len */

import React, { useState} from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';

import FeatureToggleConfiguration from './FeatureToggleConfiguration';
import FunctionConfiguration from './FunctionConfiguration';
// import OFFICE_INFO from '../../../constants/REGIONAL_OFFICE_FOR_CSS_STATION.json';

export default function UserConfiguration(props) {
// console.log(OFFICE_INFO);

  // const filteredStations = () => {
  //   let newStations = [];

  //   Object.entries(OFFICE_INFO).forEach((info) => {
  //     if (info[1] !== 'NA') {
  //       newStations.push(info);
  //     }
  //   });

  //   return newStations;
  // };

  // console.log(filteredStations());

  const [orgSelection, setOrgSelection] = useState('');

  const functionsAvailable = props.form_values.functions_available;
  const featureToggles = props.featuresList.sort();

  const organizations = props.form_values.all_organizations.sort().map((org) => ({
    value: org,
    label: org
  }));

  const handleOrgSelection = ({ value }) => {
    setOrgSelection(value);
  };

  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        // options={OFFICE_INFO.keys} searchable
        // onChange={handleUserSelect}
        // filterOption={() => true}
        // value={userSelect}
      />
      <br />
      <p>Regional Office</p>
      <SearchableDropdown
        name="Regional office dropdown"
        hideLabel
        // options={slicedUserOptions} searchable
        // onChange={handleUserSelect}
        // filterOption={() => true}
        // value={userSelect}
      />
      <br />
      <p>Organizations</p>
      <SearchableDropdown
        name="Organizations dropdown"
        hideLabel
        onChange={handleOrgSelection}
        options={organizations} searchable
        filterOption={() => true}
        value={orgSelection}
      />
      <br />
      <h2><strong>Functions</strong></h2>
      <div className="load-test-container">
        {functionsAvailable.map((functionOption) => (
          <FunctionConfiguration
            key={functionOption}
            functionOption={functionOption}
          />
        ))}
      </div>
      <br />
      <h2><strong>Feature Toggles</strong></h2>
      <div className="load-test-container">
        {featureToggles.map((featureToggle) => (
          <FeatureToggleConfiguration
            key={featureToggle}
            featureToggle={featureToggle}
          />
        ))}
      </div>
    </div>
  );
}

UserConfiguration.propTypes = {
  all_organizations: PropTypes.array,
  featuresList: PropTypes.array,
  form_values: PropTypes.object,
  functions_available: PropTypes.array
};
