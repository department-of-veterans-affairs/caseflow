import React from 'react';
import SearchableDropdown from '../components/SearchableDropdown';
import Button from '../components/Button';
import StatusMessage from '../components/StatusMessage';
import PropTypes from 'prop-types';
import ApiUtil from '../util/ApiUtil';

export default class Login extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      logInHasFailed: false,
      isLoggingIn: false,
      regionalOfficeCode: null
    };
  }

  handleSelectRegionalOffice = ({ value }) => this.setState({ regionalOfficeCode: value })
  handleClickLogin = () => {
    this.setState({ isLoggingIn: true });
    ApiUtil.patch('/sessions/update', {
      data: {
        regional_office: this.state.regionalOfficeCode
      }
    }).then(
      () => window.location = this.props.redirectTo,
      () => {
        this.setState({
          isLoggingIn: false,
          logInHasFailed: true
        });
      }
    );
  }

  render() {
    const options = this.props.regionalOfficeOptions.map((regionalOffice) => ({
      value: regionalOffice.regionalOfficeCode,
      // eslint-disable-next-line max-len
      label: `${regionalOffice.regionalOffice.city}, ${regionalOffice.regionalOffice.state} – ${regionalOffice.regionalOfficeCode}`
    }));

    return <div className="cf-app-segment--alt">
      { this.state.logInHasFailed ?
        <StatusMessage
          title="Technical Difficulties">
            It looks like Caseflow is experiencing technical difficulties right now.<br />
            Please <a href="">refresh the page</a> and try again.
        </StatusMessage> :

        <div>
          <h1>Welcome to Caseflow!</h1>
          <p>Please select the regional office you are logging in from.</p>

          <SearchableDropdown
            name="Regional office selector"
            options={options} searchable={false}
            onChange={this.handleSelectRegionalOffice}
            value={this.state.regionalOfficeCode} />

          <Button
            disabled={!this.state.regionalOfficeCode}
            onClick={this.handleClickLogin}
            name="Log in"
            loading={this.state.isLoggingIn}
            loadingText="Logging in" />
        </div>
      }

    </div>;
  }
}

Login.propTypes = {
  redirectTo: PropTypes.string.isRequired,
  regionalOfficeOptions: PropTypes.array.isRequired
};
