import React from 'react';
import { Link } from 'react-router-dom';


// TODO: refactor to use shared components where helpful
const ConfirmCaseDetails = ({ match }) => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Confirm Case Details</h2>
    </div>

    {/*
      In here:
        Check for POA information from BGS, and ensure that it matches in VACOLS.
     */}

    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <button type="button" className="cf-push-right">
        <Link to={`/certifications/${match.params.vacols_id}/sign_and_certify`}>
          Continue
        </Link>
      </button>
    </div>
  </div>;
};

export default ConfirmCaseDetails;
