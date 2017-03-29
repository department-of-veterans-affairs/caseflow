import React from 'react';
import { Link } from 'react-router-dom';

const Footer = ({nextPageUrl}) => {
  return <div>
    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
    </div>

    <Link to={nextPageUrl}>
      <button type="button" className="cf-push-right">
        Continue
      </button>
    </Link>
  </div>;
};

export default Footer;
