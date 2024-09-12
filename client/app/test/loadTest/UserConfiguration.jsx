/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';

import FeatureToggleConfiguration from './FeatureToggleConfiguration';
import FunctionConfiguration from './FunctionConfiguration';
import OrganizationDropdown from './OrganizationDropdown';
import OFFICE_INFO from '../../../constants/REGIONAL_OFFICE_FOR_CSS_STATION.json';

export default function UserConfiguration(props) {
  const [isSelectedStation, stationIsSelected] = useState(false);

  const filteredStations = [];
  const stationsMapping = new Map();

  Object.entries(OFFICE_INFO).forEach((info) => {
    if (info[1] !== 'NA') {
      if (info[1] !== Array) {
        info[1] = [info[1]];
      }
      stationsMapping.set(info[0], info[1]);
      filteredStations.push({value: info[0], label: info[0]});
    }
  });

  const handleStationSelect = () => {
    stationIsSelected(true);
  };

  const functionsAvailable = props.form_values.functions_available;
  const featureToggles = props.featuresList;
  const allOrganizations = props.form_values.all_organizations;

  featureToggles.sort();

  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        // onInputChange={handleInputChange}
        options={filteredStations} searchable
        onChange={() => {
          handleStationSelect();
        }}
        // filterOption={() => true}
        // value={userSelect}
      />
      { isSelectedStation &&
        (<div>
          <br />
          <p>Regional Office</p>
          <SearchableDropdown
            name="Regional office dropdown"
            hideLabel
            // onInputChange={handleInputChange}
            // options={slicedUserOptions} searchable
            // onChange={handleUserSelect}
            // filterOption={() => true}
            // value={userSelect}
          />
          <br />
          <p>Organizations</p>
          <div className="load-test-container">
            {allOrganizations.map((organizationOption) => (
              <OrganizationDropdown
                key={organizationOption}
                organizationOption={organizationOption}
              />
            ))}
          </div>
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
        )}
    </div>
  );
}

UserConfiguration.propTypes = {
  all_organizations: PropTypes.array,
  featuresList: PropTypes.array,
  form_values: PropTypes.object,
  functions_available: PropTypes.array
};
