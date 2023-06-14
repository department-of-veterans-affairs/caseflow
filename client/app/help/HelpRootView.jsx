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
      url: '/queue/help' },
    { name: 'VHA Help',
      url: '/vha/help' },
  ];

  return <div className="cf-help-content">

    <p><CaseFlowLink href="/search">Go Back</CaseFlowLink></p>

    <h1>Caseflow Help</h1>
    <ul id="toc" className="usa-unstyled-list">
      {pages.map(({ name, url }) =>
        <li key={name}><Link to={url}>{name}</Link></li>
      )}
    </ul>
  </div>;
};

export default HelpRootView;
