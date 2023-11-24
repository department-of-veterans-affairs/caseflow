import React from 'react';
import CorrespondenceDetailsTable from './CorrespondenceDetailsTable';

export const ConfirmCorrespondenceView = () => {

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review and Confirm Correspondence</h1>
      <p style={{ fontSize: '.85em' }}>Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <br></br>
      <div>
        <CorrespondenceDetailsTable />
      </div>
    </div>
  );
};

export default ConfirmCorrespondenceView;
