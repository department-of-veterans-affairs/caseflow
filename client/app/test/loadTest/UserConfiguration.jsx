/* eslint-disable import/extensions */
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
  const [stationSelected, setStationSelected] = useState('');
  const [isSelectedOffice, officeIsSelected] = useState(false);
  const [officeSelected, setOfficeSelected] = useState('');

  const filteredStations = [];
  const stationsMapping = new Map();

  Object.entries(OFFICE_INFO).forEach((info) => {
    if (info[1] !== 'NA') {
      if (info[1] !== Array) {
        info[1] = [info[1]];
      }
      stationsMapping.set(info[0], info[1]);
      filteredStations.push({ value: info[0], label: info[0] });
    }
  });

  const handleStationSelect = ({ value }) => {
    stationIsSelected(true);
    setStationSelected(value);
  };

  const stationAssignedOffices = OFFICE_INFO[stationSelected];

  const officeAvailable = [];
  let officesAvailable;

  if (typeof stationAssignedOffices === 'object') {
    stationAssignedOffices.forEach((station) => {
      officesAvailable = {
        value: station,
        label: station
      };
      officeAvailable.push(officesAvailable);
    });
  } else if (typeof stationAssignedOffices === 'string') {
    officeAvailable.push({ value: stationAssignedOffices, label: stationAssignedOffices });
  }

  const handleOfficeSelect = ({ value }) => {
    officeIsSelected(true);
    setOfficeSelected(value);
  };

  const functionsAvailable = props.form_values.functions_available;
  const featureToggles = props.featuresList;

  featureToggles.sort();

  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
        options={filteredStations} searchable
        onChange={(newVal) => {
          handleStationSelect(newVal);
        }}
        filterOption={() => true}
        value={stationSelected}
      />
      { isSelectedStation &&
        (<div>
          <br />
          <p>Regional Office</p>
          <SearchableDropdown
            name="Regional office dropdown"
            hideLabel
            options={officeAvailable} searchable
            onChange={(newVal) => {
              handleOfficeSelect(newVal);
            }}
            filterOption={() => true}
            value={officeSelected}
          />
          { isSelectedOffice &&
          (<div>
            <br />
            <p>Organizations</p>
            <OrganizationDropdown {...props} />
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
        )}
    </div>
  );
}

UserConfiguration.propTypes = {
  featuresList: PropTypes.array,
  form_values: PropTypes.object,
  functions_available: PropTypes.array
};
