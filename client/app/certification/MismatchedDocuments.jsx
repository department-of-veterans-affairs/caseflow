import React from 'react';
import DocumentsMismatchingBox from './DocumentsMismatchingBox';
import DocumentsCheckTable from './DocumentsCheckTable';
import { Link } from 'react-router-dom';


// TODO: refactor to use shared components where helpful
const MismatchedDocuments = ({ match }) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Check Documents</h2>
      <DocumentsMismatchingBox/>
      <DocumentsCheckTable
        form9_match={ match ? true : false }
        ssoc_dates={[dsafdsafdas]}/>
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

export default MismatchedDocuments;
