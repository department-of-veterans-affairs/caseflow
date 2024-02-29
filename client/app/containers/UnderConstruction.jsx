import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import PropTypes from 'prop-types';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';

// eslint-disable-next-line import/extensions
import COPY from '../../COPY.json';

const options = [{ title: 'Help',
  link: '/help' },
{ title: 'Switch User',
  link: '/test/users' }];

const UnderConstruction = (props) => <BrowserRouter>
  <div>
    <NavigationBar
      dropdownUrls={options}
      appName="Under Construction"
      userDisplayName="Menu"
      defaultUrl="/"
      logoProps={{
        accentColor: COLORS.GREY_DARK,
        overlapColor: COLORS.GREY_DARK
      }} />
    <AppFrame>
      <StatusMessage title= "Coming Soon!">
        { COPY.UNDER_CONSTRUCTION_MESSAGE }
      </StatusMessage>
    </AppFrame>
    <Footer
      appName="Under Construction"
      feedbackUrl={props.feedbackUrl}
      buildDate={props.buildDate} />
  </div>
</BrowserRouter>;

UnderConstruction.propTypes = {
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.object,
};

export default UnderConstruction;

