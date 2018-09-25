import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class RoSelectorDropdown extends React.Component {

  regionalOfficeOptions = () => {
    let regionalOfficeDropdowns = [];

    _.forEach(this.props.regionalOffices, (value, key) => {
      regionalOfficeDropdowns.push({
        label: `${value.city}, ${value.state}`,
        value: key
      });
    });

    regionalOfficeDropdowns.push({
      label: 'Central Office',
      value: 'C'
    });

    return _.orderBy(regionalOfficeDropdowns, (ro) => ro.label, 'asc');
  };

  render() {
    return <SearchableDropdown
      name="ro"
      label="Regional Office"
      options={this.regionalOfficeOptions()}
      onChange={this.props.onChange}
      value={this.props.value}
      placeholder=""
    />;
  }
}

RoSelectorDropdown.propTypes = {
  regionalOffices: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.object
};
