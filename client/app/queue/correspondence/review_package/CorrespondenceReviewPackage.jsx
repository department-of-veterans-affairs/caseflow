import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import ReviewPackageCmpInfo from './ReviewPackageCmpInfo';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import EditDocumentTypeModal from '../component/EditDocumentTypeModal';

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

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageCmpInfo {...props} />
        <p> Documento 1 <OpenModalLink documentName = "VA 24-0296 Direct Deposit Enrollment" /> </p>
        <p> Documento 2 <OpenModalLink documentName = "VA 24-0296 Direct Deposit Enrollment_1" /> </p>
        <p> Documento 3 <OpenModalLink documentName = "VA 24-0296 Direct Deposit Enrollment_2" /> </p>
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
          <a href="/queue/correspondence/12/intake">
            <Button
              name="Create record"
              href="/queue/correspondence/12/intake"
              classNames={['usa-button-primary']}
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

};

export default CorrespondenceReviewPackage;
