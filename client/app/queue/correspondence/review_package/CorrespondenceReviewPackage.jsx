import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import ReviewPackageData from './ReviewPackageData';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import PropTypes from 'prop-types';

export const CorrespondenceReviewPackage = (props) => {

  const intakeLink = `/queue/correspondence/${props.correspondenceId}/intake`;

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageData {...props} />
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
          <a href={intakeLink}>
            {/* hard coded UUID to link to multi_correspondence.rb data */}
            <Button
              name="Create record"
              classNames={['usa-button-primary']}
              href={intakeLink}
            />
          </a>
        </div>
      </div>
    </React.Fragment>
  );
};

CorrespondenceReviewPackage.propTypes = {
  correspondenceId: PropTypes.string
};

export default CorrespondenceReviewPackage;
