import React, { useState, useEffect } from 'react';
import CorrespondencePaginationWrapper from 'app/queue/correspondence/CorrespondencePaginationWrapper';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';


const AssociatedPriorMail = ({ priorMail, getDocumentColumns, getKeyForRow }) => (
	<div className="associatedPriorMail" style = {{ marginTop: '30px' }}>
	  <AppSegment filledBackground noMarginTop>
	    <p style = {{ marginTop: 0 }}>Please select prior mail to link to this correspondence </p>
	    <div>
	      <CorrespondencePaginationWrapper
	        columns={getDocumentColumns}
	        columnsToDisplay={15}
	        rowObjects={priorMail}
	        summary="Correspondence list"
	        className="correspondence-table"
	        headerClassName="cf-correspondence-list-header-row"
	        bodyClassName="cf-correspondence-list-body"
	        tbodyId="correspondence-table-body"
	        getKeyForRow={getKeyForRow}
	      />
	    </div>
	  </AppSegment>
	</div>
  );

 AssociatedPriorMail.propTypes = {
  priorMail: PropTypes.array.isRequired,
  getDocumentColumns: PropTypes.func.isRequired,
  getKeyForRow: PropTypes.func.isRequired,
};

export default AssociatedPriorMail;
