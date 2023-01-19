import React from 'react';
import { connect, useSelector } from 'react-redux';
import { Link } from 'react-router-dom';

const HelpRootView = (props) => {

  console.log('HelpRootView state and then props');
  console.log(props);
  // console.log(this.state);

  const organizations = useSelector((state) => state.userOrganizations);

  console.log(organizations);

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
      url: '/queue/help' }
  ];

  return <div className="cf-help-content">
    <h1>Caseflow Help</h1>
    <ul id="toc" className="usa-unstyled-list">
      {pages.map(({ name, url }) =>
        <li key={name}><Link to={url}>{name}</Link></li>
      )}
    </ul>
  </div>;
};

export default HelpRootView;
