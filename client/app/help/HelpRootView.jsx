import React from 'react';
import { Link } from 'react-router-dom';
import CaseFlowLink from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const HelpRootView = () => {

  const pages = [
    { name: 'Certification Help',
      url: '/certification/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Certification' },
    { name: 'Dispatch Help',
      url: '/dispatch/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Dispatch' },
    { name: 'Reader Help',
      url: '/reader/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Reader' },
    { name: 'Hearings Help',
      url: '/hearing_prep/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Hearings' },
    { name: 'Intake Help',
      url: '/intake/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Intake' },
    { name: 'Queue Help',
      url: '/queue/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow Queue' },
    { name: 'VHA Help',
      url: '/vha/help',
      ariaLabel: 'Click for help resources/frequently asked questions on using Caseflow VHA' },
  ];

  return <div className="cf-help-content">

    <p><CaseFlowLink href="/search">Go Back</CaseFlowLink></p>

    <h1 aria-label="Caseflow help resources page. Choose one of the links below" tabIndex={0}>Caseflow Help</h1>
    <ul id="toc" className="usa-unstyled-list">
      {pages.map(({ name, url, ariaLabel }) =>
        <li key={name}><Link to={url} aria-label={ariaLabel}>{name}</Link></li>
      )}
    </ul>
  </div>;
};

export default HelpRootView;
