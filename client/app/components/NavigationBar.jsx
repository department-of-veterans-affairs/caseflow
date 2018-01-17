import React from 'react';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import NavigationBar from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/NavigationBar';

export default class CaseflowNavigationBar extends React.PureComponent {
  render = () => <NavigationBar extraBanner={<PerformanceDegradationBanner />} {...this.props} />
}
