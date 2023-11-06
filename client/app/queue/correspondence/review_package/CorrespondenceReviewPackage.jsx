import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';

import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';

export const CorrespondenceReviewPackage = () => {

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
      </AppSegment>
      <div className="cf-app-segment">
        <div className="cf-push-left">
          <a href="/queue/correspondence">
            <Button
              name="Cancel"
              href="/queue/correspondence"
              classNames={['cf-btn-link']}
            />
          </a>
        </div>
        <div className="cf-push-right">
          <Button
            name="Intake appeal"
            styling={{ style: { marginRight: '2rem' } }}
            classNames={['usa-button-secondary']}
          />
          <a href="/queue/correspondence/9d912a08-7847-436f-9c58-bdf3896be2f1/intake">
            {/* hard coded UUID to link to multi_correspondence.rb data */}
            <Button
              name="Create record"
              classNames={['usa-button-primary']}
              href="/queue/correspondence/9d912a08-7847-436f-9c58-bdf3896be2f1/intake"
            />
          </a>
        </div>
      </div>
    </React.Fragment>
  );
};

export default CorrespondenceReviewPackage;
