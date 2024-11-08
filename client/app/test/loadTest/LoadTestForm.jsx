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
  let showScenarios = Object.keys(currentState.user.user.regional_office).length !== 0;

  const onSubmit = (event) => {
    event.preventDefault();
    // the variable of organizationsObject is set to the single object held within the array.
    // this is because of how it is set through the updateState method. properlyFormatOrgsArray
    // is a method in whice we interate through that single object of the array and instead reformat it so that it holds
    // multiple object. each of which will have a url and admin key.
    const organizationsObject = currentState.user.user.organizations[0];
    const properlyFormattedOrgsArray = Object.keys(organizationsObject).flatMap((orgName) => {
      return orgName.endsWith('-admin') ? {} : {
        url: orgName,
        // eslint-disable-next-line no-prototype-builtins
        admin: organizationsObject.hasOwnProperty(`${orgName}-admin`) ?? false
      };
    });
    const payload = JSON.stringify({
      data: {
        scenarios: currentState.scenarios,
        user: {
          user: {
            station_id: currentState.user.user.station_id,
            regional_office: currentState.user.user.regional_office,
            roles: currentState.user.user.roles,
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
            <h1>Welcome to the Caseflow Load Test page</h1>
            <h2>User Configuration</h2>
            <UserConfiguration {...props} updateState={updateState} currentState={currentState} />
            <br />
            { showScenarios &&
            <>
              <h2>Scenario Groups</h2>
              <ScenarioConfigurations {...props} updateState={updateState} currentState={currentState} />
            </>
            }
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
