import React from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import AppFrame from '../../components/AppFrame';
import { BrowserRouter } from 'react-router-dom';
import { css } from 'glamor';
import { useForm } from 'react-hook-form';

import Button from '../../components/Button';

import UserConfiguration from './UserConfiguration';

export default function LoadTest(props) {
  const { register, handleSubmit } = useForm();

  const onSubmit = () => {
    console.log();
  }

  return <BrowserRouter>
    <div>
      <AppFrame>
        <form onSubmit={handleSubmit(onSubmit)}>
          <AppSegment filledBackground>
            <h1>Test Target Configuration</h1>
            <UserConfiguration {...props} register={register} />
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
