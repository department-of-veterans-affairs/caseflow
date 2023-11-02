
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import ReviewPackageCmpInfo from './ReviewPackageCmpInfo';  
import Button from '../../../components/Button';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';

export const CorrespondenceReviewPackage = (props) => {
  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageCmpInfo {...props} />
      </AppSegment>
      <div className="cf-app-segment">
        <div className="cf-push-left">
          <a href="/queue/correspondences">
            <Button
              name="Cancel"
              href="/queue/correspondences"
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
          <a href="/queue/correspondence/12/intake">
            <Button
              name="Create record"
              href="/queue/correspondence/12/intake"
              classNames={['usa-button-primary']}
            />
          </a>
        </div>
      </div>
    </React.Fragment>
  );
};

export default CorrespondenceReviewPackage;
