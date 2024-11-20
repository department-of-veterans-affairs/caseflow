import React, { useState } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { css } from 'glamor';

import Button from '../../components/Button';

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

        if (!scenario[key].targetType) {
          newErrors[key] = { target_type: '' };
          newErrors[key].target_type = 'Target Type Required';
        }
      });
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
    } else {
      const payload = JSON.stringify({ currentState });

      ApiUtil.post('/test/load_tests/run_load_tests', payload);
    }
  };

  return <BrowserRouter>
    <div>
      <AppFrame>
        <form onSubmit={onSubmit} >
          <AppSegment filledBackground>
            <h1>Welcome to the Caseflow Load Test page</h1>
            <h2>User Configuration</h2>
            <UserConfiguration {...props} updateState={updateState} currentState={currentState} errors={errors} />
            <br />
            <h2 className="header-style">Scenario Groups</h2>
            {errors.scenarios && <div className="error">{errors.scenarios}</div>}
            <ScenarioConfigurations {...props} updateState={updateState} currentState={currentState} errors={errors} />
          </AppSegment>
          <div {...css({ overflow: 'hidden' })}>
            <Button
              id="Cancel"
              name="Cancel"
              linkStyling
              styling={css({ float: 'left', paddingLeft: 0, paddingRight: 0 })}
            >
              Cancel
            </Button>
            <span {...css({ float: 'right' })}>
              <Button
                id="Submit"
                name="Submit"
                type="submit"
                className="usa-button"
              />
            </span>
          </div>
        </form>
      </AppFrame>
    </div>
  </BrowserRouter>;
}

LoadTestForm.propTypes = {
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
