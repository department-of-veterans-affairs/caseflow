import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { css } from 'glamor';
import { useForm } from 'react-hook-form';

import Button from '../../components/Button';

import UserConfiguration from './UserConfiguration';
import ScenarioConfigurations from './ScenarioConfigurations';

export default function LoadTestForm(props) {
  const { handleSubmit } = useForm();

  const currentState = props.currentState;

  const onSubmit = (event) => {
    event.preventDefault();
    console.log(currentState);
  };

  const updateState = props.updateState;

  return <BrowserRouter>
    <div>
      <AppFrame>
        <form onSubmit={handleSubmit(onSubmit)} >
          <AppSegment filledBackground>
            <h1>Test Target Configuration</h1>
            <UserConfiguration {...props} updateState={updateState} />
            <br />
            <h2>Scenario Groups</h2>
            <ScenarioConfigurations />
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
