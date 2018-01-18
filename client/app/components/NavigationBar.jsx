import React from 'react';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import NavigationBar from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/NavigationBar';
import {withRouter} from 'react-router';

class CaseflowNavigationBar extends React.PureComponent {
  render = () => <NavigationBar extraBanner={<PerformanceDegradationBanner />} {...this.props} />
}

// When a PureComponent has <Route> children, they will not re-render under certain conditions
// unless we wrap the PureComponent in withRouter.
export default withRouter(CaseflowNavigationBar);
