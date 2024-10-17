/* eslint-disable max-lines, max-len */

import React from 'react';
import PropTypes from 'prop-types';
import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios';
import ScenarioConfiguration from './ScenarioConfiguration';

export default function ScenarioConfigurations(props) {
  let loadTestScenarios = LOAD_TEST_SCENARIOS;
  const currentState = props.currentState;
  const updateState = props.updateState;

  return (
    <div className="load-test-container">
      { loadTestScenarios.map((scenarioGroup) => (
        <ScenarioConfiguration
          key={scenarioGroup.scenario}
          scenario={scenarioGroup.scenario}
          targetType={scenarioGroup.targetType}
          currentState={currentState}
          updateState={updateState}
        />
      ))}
    </div>
  );
}

ScenarioConfigurations.propTypes = {
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
