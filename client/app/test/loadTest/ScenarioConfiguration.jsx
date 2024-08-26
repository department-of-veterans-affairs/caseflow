/* eslint-disable max-lines, max-len */

import React from 'react';

import SearchableDropdown from '../../components/SearchableDropdown';
import Checkbox from '../../components/Checkbox';
import LOAD_TEST_SCENARIOS from '../../../constants/LoadTestScenarios.json';

export default function ScenarioConfiguration() {

  return (
    <div>
      <p>Station ID</p>
      <SearchableDropdown
        name="Station id dropdown"
        hideLabel
      />
      <br />
      <p>Regional Office</p>
      <SearchableDropdown
        name="Regional office dropdown"
        hideLabel
      />
    </div>
  );
}
