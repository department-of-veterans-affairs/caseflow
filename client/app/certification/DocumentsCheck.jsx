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
      <DocumentsCheckTable form9_match = { true }
        form9_date = "09/31/2099"
        nod_match = { true }
        nod_date = "04/10/2010"
        soc_match = { true }
        soc_date = "03/19/2007"
        ssoc_dates = {["02/22/2007", "03/22/2007"]}/>
    </div>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <Link
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}>
        <button type="button" className="cf-push-right">
          Continue
        </button>
      </Link>
    </div>
  </div>;
};

export default DocumentsCheck;
