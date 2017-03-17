import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Redirect } from 'react-router-dom';


// TODO: refactor to use shared components where helpful
const DocumentsCheckSuccess = () => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Check Documents</h2>
      <DocumentsMatchingBox/>
      <DocumentsCheckTable/>
    </div>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <button type="button" className="cf-push-right">
        Continue
      </button>
    </div>
  </div>;
};

export default DocumentsCheckSuccess;
