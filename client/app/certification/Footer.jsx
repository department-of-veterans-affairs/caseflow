import React from 'react';
import Button from '../components/Button';

// TODO: use the footer (see ConfirmHearing.jsx) everywhere,
// then delete this comment :)
const Footer = ({ onClickContinue, disableContinue, loading }) => {
  return <div>
    <div className="cf-app-segment">
      <a href="#confirm-cancel-certification"
        className="cf-action-openmodal cf-btn-link">
        Cancel Certification
      </a>
      <Button type="button"
        name="Continue"
        classNames={["cf-push-right"]}
        onClick={onClickContinue}
        loading={loading}
        disabled={disableContinue}>
        Continue
      </Button>
    </div>
  </div>;
};

export default Footer;
