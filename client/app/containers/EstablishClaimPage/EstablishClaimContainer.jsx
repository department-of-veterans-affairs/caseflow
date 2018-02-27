import React from 'react';
import PropTypes from 'prop-types';
import Alert from '../../components/Alert';

import EstablishClaim from './EstablishClaim';
import EstablishClaimComplete from './EstablishClaimComplete';
import EstablishClaimCancel from './EstablishClaimCanceled';

const Pages = {
  EstablishClaim,
  EstablishClaimCancel,
  EstablishClaimComplete
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

    return <div>
      {alert && <div className="cf-app-segment">
        <Alert
          type={alert.type}
          title={alert.title}
          message={alert.message}
          handleClear={this.handleAlertClear}
        />
      </div>}
      <PageComponent
        {...rest}
        handleAlert={this.handleAlert}
        handleAlertClear={this.handleAlertClear}
      />
    </div>;
  }
}

EstablishClaimContainer.propTypes = {
  page: PropTypes.string.isRequired
};
