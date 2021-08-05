import React from 'react';
import AppFrame from '../components/AppFrame';
import NavigationBar from '../components/NavigationBar';
import StatusMessage from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/StatusMessage';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import { BrowserRouter } from 'react-router-dom';
import COPY from '../../COPY';
import PropTypes from 'prop-types';

export const Error403 = (props) => {
  const options = [{ title: 'Help',
    link: '/help' },
  { title: 'Switch User',
    link: '/test/users' }];

  return <BrowserRouter>
    <div>
      <NavigationBar
        dropdownUrls={options}
        appName="Error 403"
        userDisplayName="Menu"
        defaultUrl="/"
        logoProps={{
          accentColor: COLORS.GREY_DARK,
          overlapColor: COLORS.GREY_DARK
        }} />
      <AppFrame>
        <StatusMessage title={props.errorTitle} type="alert">
          {props.errorDetail}
        </StatusMessage>
      </AppFrame>
      <Footer
        appName="Help"
        feedbackUrl={props.feedbackUrl}
        buildDate={props.buildDate} />
    </div>
  </BrowserRouter>;
};

Error403.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  buildDate: PropTypes.string,
  errorTitle: PropTypes.string,
  errorDetail: PropTypes.string,
};
