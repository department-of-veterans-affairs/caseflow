import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import Alert from '../../components/Alert';
import AppFrame from '../../components/AppFrame';
import NavigationBar from '../../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { LOGO_COLORS } from '../../constants/AppConstants';

import EstablishClaimHeader from './EstablishClaimHeader';
import EstablishClaim from './EstablishClaim';
import EstablishClaimComplete from './EstablishClaimComplete';
import EstablishClaimCancel from './EstablishClaimCanceled';
import UnpreparedTasksIndex from './UnpreparedTasksIndex';
import CanceledTasksIndex from './CanceledTasksIndex';

import TestPage from '../TestPage';

const Pages = {
  EstablishClaim,
  EstablishClaimCancel,
  EstablishClaimComplete,
  UnpreparedTasksIndex,
  CanceledTasksIndex,
  TestPage
};

export default class EstablishClaimContainer extends React.Component {
  constructor(props) {
    super(props);
    this.state = { alert: null };
  }

  handleAlert = (type, title, message) => {
    this.setState({
      alert: {
        message,
        title,
        type
      }
    });
  }

  handleAlertClear = () => {
    this.setState({ alert: null });
  }

  render() {
    let {
      page,
      ...rest
    } = this.props;

    let {
      alert
    } = this.state;

    let PageComponent = Pages[page];

    return <BrowserRouter>
      <React.Fragment>
        <NavigationBar
          dropdownUrls={this.props.dropdownUrls}
          appName="Dispatch"
          userDisplayName={this.props.userDisplayName}
          defaultUrl="/dispatch/establish-claim/"
          logoProps={{
            accentColor: LOGO_COLORS.DISPATCH.ACCENT,
            overlapColor: LOGO_COLORS.DISPATCH.OVERLAP
          }} />
        {alert && <div className="cf-app-segment">
          <Alert
            type={alert.type}
            title={alert.title}
            message={alert.message}
            handleClear={this.handleAlertClear}
          />
        </div>}
        <AppFrame>
          {this.props.task && <EstablishClaimHeader appeal={this.props.task.appeal} />}
          <PageComponent
            {...rest}
            handleAlert={this.handleAlert}
            handleAlertClear={this.handleAlertClear}
          />
          <Footer
            appName="Dispatch"
            feedbackUrl={this.props.feedbackUrl}
            buildDate={this.props.buildDate} />
        </AppFrame>
      </React.Fragment>
    </BrowserRouter>;
  }
}

EstablishClaimContainer.propTypes = {
  page: PropTypes.string.isRequired
};
