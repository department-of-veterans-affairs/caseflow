import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useState } from 'react';
import ReviewPackageCmpInfo from './ReviewPackageCmpInfo';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import EditDocumentTypeModal from '../component/EditDocumentTypeModal';
import PropTypes from 'prop-types';

export const CorrespondenceReviewPackage = (props) => {
  const [modalState, setModalState] = useState(false);
  const [documentName, setDocumentName] = useState('');

  const openModal = () => {
    setModalState(true);
  };
  const closeModal = () => {
    setModalState(false);
  };

  const OpenModalLink = (newValue) => (
    <Button linkStyling onClick={() => {
      setDocumentName(newValue);
      openModal();
    }} >
      <span>Edit</span>
    </Button>
  );

  OpenModalLink.propTypes = {
    documentName: PropTypes.string
  };

  const intakeLink = `/queue/correspondence/${props.correspondenceId}/intake`;

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageCmpInfo {...props} />
        <p> Documento 1 <OpenModalLink documentName = "030" /> </p>
        <p> Documento 2 <OpenModalLink documentName = "0779" /> </p>
        <p> Documento 3 <OpenModalLink documentName = "VA 24-0296 Direct Deposit Enrollment" /> </p>
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
      {modalState &&
        <EditDocumentTypeModal
          modalState={modalState}
          onCancel={closeModal}
          document={documentName}
        />
      }
    </React.Fragment>

  );
};

CorrespondenceReviewPackage.propTypes = {
  correspondenceId: PropTypes.string,
};

export default CorrespondenceReviewPackage;
