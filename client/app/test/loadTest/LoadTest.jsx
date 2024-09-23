import { React } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { css } from 'glamor';
import { LoadTestContext } from './LoadTestContext';

import Button from '../../components/Button';

import UserConfiguration from './UserConfiguration';

export default function LoadTest(props) {
  // const = dataPac

  const handleSubmit = () => {

    // grabbing all inputed information in form and build a JSON object that resembles exampleSetup.json in k6repo.
  };

  return (
    <BrowserRouter>
      <div>
        <AppFrame>
          <LoadTestContext.Provider >
            <form onSubmit={handleSubmit}>
              <AppSegment filledBackground>
                <h1>Test Target Configuration</h1>
                <UserConfiguration {...props} />
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
            </form>
          </LoadTestContext.Provider>
        </AppFrame>
      </div>
    </BrowserRouter>);
}
