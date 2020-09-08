import React from 'react';
import PropTypes from 'prop-types';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import NavigationBar from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/NavigationBar';
import { withRouter } from 'react-router';

class CaseflowNavigationBar extends React.PureComponent {
  render = () => <NavigationBar
    key={this.props.location.pathname}
    extraBanner={<PerformanceDegradationBanner />}
    {...this.props} />
}

CaseflowNavigationBar.propTypes = {
  location: PropTypes.object
};

// When a PureComponent has <Route> children, they will not re-render under certain conditions
// unless we wrap the PureComponent in withRouter.
export default withRouter(CaseflowNavigationBar);
