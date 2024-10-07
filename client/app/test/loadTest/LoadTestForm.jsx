import React from 'react';
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

  const onSubmit = (event) => {
    event.preventDefault();
    const organizationsObject = currentState.user.user.organizations[0];

    const properlyFormattedOrgsArray = Object.keys(organizationsObject).map((orgName) => ({
      url: orgName,
      // eslint-disable-next-line no-prototype-builtins
      admin: organizationsObject.hasOwnProperty(`${orgName}-admin`) ?? false
    }));
    const payload = JSON.stringify({
      data: {
        scenarios: [],
        user: {
          user: {
            station_id: currentState.user.user.station_id,
            regional_office: currentState.user.user.regional_office,
            roles: [],
            functions: currentState.user.user.functions,
            organizations: properlyFormattedOrgsArray,
            feature_toggles: currentState.user.user.feature_toggles
          }
        }
      }
    });
    ApiUtil.post('/test/load_tests/run_load_tests', payload);

  };

  return <BrowserRouter>
    <div>
      <AppFrame>
        <form onSubmit={onSubmit} >
          <AppSegment filledBackground>
            <h1>Test Target Configuration</h1>
            <UserConfiguration {...props} updateState={updateState} currentState={currentState} />
            <br />
            <h2>Scenario Groups</h2>
            <ScenarioConfigurations {...props} updateState={updateState} currentState={currentState} />
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
