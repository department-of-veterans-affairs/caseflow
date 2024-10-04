import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { css } from 'glamor';

import Button from '../../components/Button';

import UserConfiguration from './UserConfiguration';
import ScenarioConfigurations from './ScenarioConfigurations';

export default function LoadTest(props) {

  return <BrowserRouter>
    <div>
      <AppFrame>
        <AppSegment filledBackground>
          <h1>Test Target Configuration</h1>
          <UserConfiguration {...props} />
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
              className="usa-button"
            />
          </span>
        </div>
      </AppFrame>
    </div>
  </BrowserRouter>;
}
