/* eslint-disable max-lines, max-len */

import React, {useState} from 'react';

import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios.json';
import ScenarioConfiguration from './ScenarioConfiguration';

export default function ScenarioConfigurations(){
  let loadTestScenarios = LOAD_TEST_SCENARIOS;

  loadTestScenarios.map((scenarioGroup) => console.log(scenarioGroup));

  console.log("successful process");
  //console.log(scenarioConfigurations);

  return (
    <div>
      { loadTestScenarios.map((scenarioGroup) => (
      <ScenarioConfiguration
        key={scenarioGroup["scenario"]}
        scenario={scenarioGroup["scenario"]}
        targetType={scenarioGroup["targetType"]}
      />
  )) }
    </div>
  );
}
