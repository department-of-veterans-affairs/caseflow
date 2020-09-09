import React from 'react';
import PropTypes from 'prop-types';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import NavigationBar from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/NavigationBar';
import { withRouter } from 'react-router';

class CaseflowNavigationBar extends React.PureComponent {
  render = () => <NavigationBar
    // Forces NavigationBar PureComponent to update when the user navigates FROM any page TO /queue. This will force
    // queue loading screen to request the user's queue from the backend
    key={this.props.location.pathname === '/queue'}
    extraBanner={<PerformanceDegradationBanner />}
    {...this.props} />
}

CaseflowNavigationBar.propTypes = {
  location: PropTypes.object
};

// When a PureComponent has <Route> children, they will not re-render under certain conditions
// unless we wrap the PureComponent in withRouter.
export default withRouter(CaseflowNavigationBar);
