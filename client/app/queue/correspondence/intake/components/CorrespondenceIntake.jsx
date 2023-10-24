import React, { useMemo } from 'react';
// import PropTypes from 'prop-types';
import { Switch } from 'react-router';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

let backActive = true;
let submitActive = true;

const progressBarSections = [
  {
    title: '1. Add Related Correspondence',
    current: false
  },
  {
    title: '2. Review Tasks & Appeals',
    current: true
  },
  {
    title: '3. Confirm',
    current: false
  },
];

// let activateBack = () => {
//   !backActive;
// }

export const CorrespondenceIntake = () => {
  const sections = useMemo(
    () =>
      progressBarSections.map(({ title, current }) => ({
        title,
        current
      })),
  );

  return <div>
    <AppSegment>
      <ProgressBar sections={sections} />
      <Switch>
        <div>
          <a href="/queue/correspondence">
            <Button
              name="Cancel"
              classNames={['cf-btn-link']}
            />
          </a>
          {submitActive && <Button
            type="button"
            name="Submit"
            classNames={['cf-push-right']}>
              Submit
          </Button> }
          {!submitActive && <Button
            type="button"
            name="Continue"
            classNames={['cf-push-right']}>
              Continue
          </Button> }
          { backActive && <Button
            type="button"
            name="Back"
            classNames={['padding', 'cf-push-right']}>
              Back
          </Button> }
        </div>
      </Switch>
    </AppSegment>
  </div>;
};

export default CorrespondenceIntake;
