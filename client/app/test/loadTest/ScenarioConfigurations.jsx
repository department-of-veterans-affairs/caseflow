/* eslint-disable max-lines, max-len */

import React from 'react';

import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios';
import ScenarioConfiguration from './ScenarioConfiguration';

export default function ScenarioConfigurations() {
  let loadTestScenarios = LOAD_TEST_SCENARIOS;

  return (
    <div className="load-test-container">
      { loadTestScenarios.map((scenarioGroup) => (
        <ScenarioConfiguration
          key={scenarioGroup.scenario}
          scenario={scenarioGroup.scenario}
          targetType={scenarioGroup.targetType}
        />
      ))}
    </div>
  );
}
