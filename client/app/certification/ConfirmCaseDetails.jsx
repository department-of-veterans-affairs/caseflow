import React from 'react';
import { Link } from 'react-router-dom';
import LoadingContainer from '../components/LoadingContainer';


// TODO: refactor to use shared components where helpful
const ConfirmCaseDetails = ({ match }) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Confirm Case Details</h2>
    </div>

    <LoadingContainer>
      <iframe
        aria-label="The PDF embedded here is not accessible. Please use the above
          link to download the PDF and view it in a PDF reader. Then use the
          buttons below to go back and make edits or upload and certify
          the document."
        className="cf-doc-embed cf-iframe-with-loading"
        title="Form8 PDF"
        src={`/certifications/${match.params.vacols_id}/form9_pdf`}>
      </iframe>
    </LoadingContainer>

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
        <Link to={`/certifications/${match.params.vacols_id}/sign_and_certify`}>
          <button type="button" className="cf-push-right">
            Continue
          </button>
        </Link>
    </div>
  </div>;
};

export default ConfirmCaseDetails;
