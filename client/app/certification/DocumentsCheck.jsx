import React from 'react';
import DocumentsMatchingBox from './DocumentsMatchingBox';
import DocumentsNotMatchingBox from './DocumentsNotMatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Link } from 'react-router-dom';


// TODO: refactor to use shared components where helpful
const DocumentsCheck = ({ match }) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Check Documents</h2>
      { match ? <DocumentsMatchingBox/> : <DocumentsNotMatchingBox/> }
      <DocumentsCheckTable form9Match = { true }
        form9Date = "09/31/2099"
        nodMatch = { true }
        nodDate = "04/10/2010"
        socMatch = { true }
        socDate = "03/19/2007"
        ssocDates = {["02/22/2007", "03/22/2007"]}/>
    </div>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <Link
        to={`/certifications/${match.params.vacols_id}/confirm_case_details`}>
        <button type="button" className="cf-push-right">
          Continue
        </button>
      </Link>
    </div>
  </div>;
};

export default DocumentsCheck;
