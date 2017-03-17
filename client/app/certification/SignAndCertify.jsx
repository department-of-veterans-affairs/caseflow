import React from 'react';

// TODO: refactor to use shared components where helpful
const SignAndCertify = () => {
  return <div>
    <div className="cf-app-segment cf-app-segment--alt">
      <h2>Sign and Certify</h2>
    </div>

    {/*
      Here, we'll add the name/organization/title/date questions and finalize the certification.
    */}

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

export default SignAndCertify;
