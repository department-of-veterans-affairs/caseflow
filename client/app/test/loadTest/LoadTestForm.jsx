import React, { useState } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import Button from '../../components/Button';
import LOAD_TEST_SCENARIOS from '../../constants/LoadTestScenarios';
import UserConfiguration from './UserConfiguration';
import ScenarioConfigurations from './ScenarioConfigurations';
import ApiUtil from '../../util/ApiUtil';

export default function LoadTestForm(props) {

  const currentState = props.currentState;
  const updateState = props.updateState;
  const [errors, setErrors] = useState({});

  const onSubmit = (event) => {
    event.preventDefault();
    setErrors({});
    const newErrors = {};
    const importedScenarios = LOAD_TEST_SCENARIOS;

    if (currentState.user.station_id.length === 0) {
      newErrors.station_id = 'Station ID Required';
    }
    if (currentState.user.regional_office.length === 0) {
      newErrors.regional_office = 'Regional Office Required';
    }
    if (currentState.scenarios.length === 0) {
      newErrors.scenarios = 'Select at least 1 Target Scenario';
    } else {
      currentState.scenarios.forEach((scenario) => {
        const key = Object.keys(scenario)[0];
        const chosenScenario = importedScenarios.find((currentScenario) => currentScenario.scenario === key);

        if ((!scenario[key].targetType) && (chosenScenario.targetType.length > 0)) {
          newErrors[key] = { target_type: '' };
          newErrors[key].target_type = 'Target Type Required';
        }
      });
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
    } else {

      ApiUtil.post('/test/load_tests/run_load_tests', { data: currentState });
      props.setShowAlert(true);
      setTimeout(() => {
        window.location = '/test/load_tests';
      }, 5000);
    }
  };

  return <form onSubmit={onSubmit} >
    <AppSegment filledBackground>
      <h1>Welcome to the Caseflow Load Test page</h1>
      <h2>User Configuration</h2>
      <UserConfiguration {...props} updateState={updateState} currentState={currentState} errors={errors} />
      <br />
      <h2 className="header-style">Scenario Groups</h2>
      {errors.scenarios && <div className="error">{errors.scenarios}</div>}
      <ScenarioConfigurations {...props} updateState={updateState} currentState={currentState} errors={errors} />
    </AppSegment>
    <div className="load-test-submit">
      <Button
        id="Submit"
        name="Submit"
        type="submit"
        className="usa-button"
      />
    </div>
  </form>;
}

LoadTestForm.propTypes = {
  currentState: PropTypes.object,
  updateState: PropTypes.func,
  setShowAlert: PropTypes.func
};
