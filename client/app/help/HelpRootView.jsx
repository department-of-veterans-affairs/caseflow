import React from 'react';
import { Link } from 'react-router-dom';
import CaseFlowLink from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const HelpRootView = () => {

  const pages = [
    { name: 'Certification Help',
      url: '/certification/help' },
    { name: 'Dispatch Help',
      url: '/dispatch/help' },
    { name: 'Reader Help',
      url: '/reader/help' },
    { name: 'Hearings Help',
      url: '/hearing_prep/help' },
    { name: 'Intake Help',
      url: '/intake/help' },
    { name: 'Queue Help',
      url: '/queue/help',
      alt: "Learn Caseflow Intake and Frequently Asked Questions",
      ariaLabel: "Learn Caseflow Intake and Frequently Asked Questions" },
    { name: 'VHA Help',
      url: '/vha/help' },
  ];

  return <div className="cf-help-content">

    <p><CaseFlowLink href="/search">Go Back</CaseFlowLink></p>

    <h1>Caseflow Help</h1>
    <ul id="toc" className="usa-unstyled-list">
      {pages.map(({ name, url, alt, ariaLabel }) =>
        <li key={name} ariaLabel={ariaLabel}><Link to={url} ariaLabel={ariaLabel} alt={alt}>{name}</Link></li>
      )}
    </ul>
  </div>;
};

export default HelpRootView;
