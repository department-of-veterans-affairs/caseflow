import React from 'react';
import { useSelector } from 'react-redux';
import moment from 'moment';

// import PropTypes from 'prop-types';

export const ConfirmCorrespondenceView = () => {

  const currentCorrespondence = useSelector((state) => state.intakeCorrespondence.currentCorrespondence);
  const veteranInformation = useSelector((state) => state.intakeCorrespondence.veteranInformation);

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review and Confirm Correspondence</h1>
      <p>Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <br></br>
      <div>
        <h2 className="cf-review-about-correspondence">About the Correspondence</h2>
        <div className="correspondence-label-row">
          <h3 className="cf-app-segment">Portal Entry Date</h3>
          <p>{moment(currentCorrespondence.portal_entry_date).format('MM/DD/YYYY')}</p>
          <h3 className="cf-app-segment">Source Type</h3>
          <p>{currentCorrespondence.source_type}</p>
          <h3 className="cf-app-segment">Package Document Type</h3>
          <p>{currentCorrespondence.package_document_type_id}</p>
          <h3 className="cf-app-segment">CM Packet Number</h3>
          <p>{currentCorrespondence.cmp_packet_number}</p>
          <h3 className="cf-app-segment">CMP Queue Name</h3>
          <p>{currentCorrespondence.cmp_queue_id}</p>
          <h3 className="cf-app-segment">VA DOR</h3>
          <p>{moment(currentCorrespondence.va_date_of_receipt).format('MM/DD/YYYY')}</p>
        </div>
        <div className="cf-">
          <h3 className="cf-app-segment">Veteran</h3>
          <p>{veteranInformation.first_name} {veteranInformation.last_name} ({veteranInformation.file_number})</p>
          <h3 className="cf-app-segment">Correspondence Type</h3>
          <p>{currentCorrespondence.correspondence_type_id}</p>
          <br></br>
          <h3 className="cf-app-segment">Notes</h3>
          <p>{currentCorrespondence.notes}</p>
        </div>
      </div>
    </div>
  );
};

export default ReviewConfirmCorrespondenceView;
