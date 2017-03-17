import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Link } from 'react-router-dom';


// TODO: refactor to use shared components where helpful
const DocumentsCheckSuccess = ({ match }) => {
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
        {/* TODO: since this is nested inside the button,
         you need to click the text inside the button to have the link work.
         Sad! Pleasefix. */}
        <Link className="cf-white-text"
          to={`/certifications/${match.params.vacols_id}/confirm_case_details`}>
          Continue
        </Link>
      </button>
    </div>
  </div>;
};

export default DocumentsCheckSuccess;
