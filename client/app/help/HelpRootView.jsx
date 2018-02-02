import React from 'react';
import { Link } from 'react-router-dom'

class HelpRootView extends React.Component {

  render() {
    return <div className="cf-help-content">
      <h1>Caseflow Help</h1>
      <ul id="toc" className="usa-unstyled-list">
        <li><Link to="/certification/help">Certification Help</Link></li>
        <li><Link to="/dispatch/help">Dispatch Help</Link></li>
        <li><Link to="/reader/help">Reader Help</Link></li>
        <li><Link to="/hearings/help">Hearings Help</Link></li>
        <li><Link to="/intake/help">Intake Help</Link></li>
      </ul>
    </div>;
  }
}

export default HelpRootView;
