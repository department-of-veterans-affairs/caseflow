/* eslint-disable import/extensions */
/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../components/SearchableDropdown';

import FeatureToggleConfiguration from './FeatureToggleConfiguration';
import FunctionConfiguration from './FunctionConfiguration';
import OFFICE_INFO from '../../../constants/REGIONAL_OFFICE_FOR_CSS_STATION';
import OrgCheckboxSection from './OrgCheckboxSection';

export default function UserConfiguration(props) {
  const [stationSelected, setStationSelected] = useState('');
  const [isSelectedStation, stationIsSelected] = useState(false);
  const [isSelectedOffice, officeIsSelected] = useState(false);
  const [officeSelected, setOfficeSelected] = useState('');

  const filteredStations = [];
  const stationsMapping = new Map();

  const functionsAvailable = props.form_values.functions_available;
  const featureToggles = props.featuresList;
  const currentState = props.currentState;
  const updateState = props.updateState;

  const handleStationSelect = ({ value }) => {
    stationIsSelected(true);
    setStationSelected(value);
    updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          user: {
            ...currentState.user.user,
            station_id: value
          }
        }
      }
    );
  };

  Object.entries(OFFICE_INFO).forEach((info) => {
    if (info[1] !== 'NA') {
      if (info[1] !== Array) {
        info[1] = [info[1]];
      }
      stationsMapping.set(info[0], info[1]);
      filteredStations.push({ value: info[0], label: info[0] });
    }
  });

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
    props.updateState(
      {
        ...currentState,
        user: {
          ...currentState.user,
          user: {
            ...currentState.user.user,
            regional_office: value
          }
        }
      }
    );
  };

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
              <div className="load-test-container">
                <OrgCheckboxSection {...props} />
              </div>
              <br />
              <h2><strong>Functions</strong></h2>
              <div className="load-test-container test-class-sizing">
                {functionsAvailable.map((functionOption) => (
                  <FunctionConfiguration
                    key={functionOption}
                    functionOption={functionOption}
                    currentState={currentState}
                    updateState={props.updateState}
                  />
                ))}
              </div>
              <br />
              <h2><strong>Feature Toggles</strong></h2>
              <div className="load-test-container test-class-sizing">
                {featureToggles.map((featureToggle) => (
                  <FeatureToggleConfiguration
                    key={featureToggle}
                    featureToggle={featureToggle}
                    currentState={currentState}
                    updateState={props.updateState}
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
  all_organizations: PropTypes.array,
  featuresList: PropTypes.array,
  form_values: PropTypes.object,
  functions_available: PropTypes.array,
  register: PropTypes.func,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
