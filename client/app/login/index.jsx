import React from 'react';
import SearchableDropdown from '../components/SearchableDropdown';
import PropTypes from 'prop-types';

export default class Login extends React.PureComponent {
  render() {
    const options = this.props.regionalOfficeOptions.map((regionalOffice) => ({
      value: regionalOffice.regionalOfficeCode,
      label: `${regionalOffice.regionalOffice.city}, ${regionalOffice.regionalOffice.state} – ${regionalOffice.regionalOfficeCode}`
    }));

    return <div className="cf-app-segment">
      <h1>Welcome to Caseflow!</h1>
      <p>Please select the regional office you are logging in from.</p>

      <SearchableDropdown name="RO selector" options={options} searchable={false} />

      <button type="submit">Login</button>
    </div>;
  }
}

Login.propTypes = {
  regionalOfficeOptions: PropTypes.array.isRequired
}