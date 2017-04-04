import React from 'react';
import { Link } from 'react-router-dom';


// TODO: use the footer (see ConfirmHearing.jsx) everywhere,
// then delete this comment :)
const Footer = ({ nextPageUrl }) => {
  return <div>
    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
    <Link to={nextPageUrl}>
      <button type="button" className="cf-push-right">
        Continue
      </button>
    </Link>
    </div>
  </div>;
};

export default Footer;
