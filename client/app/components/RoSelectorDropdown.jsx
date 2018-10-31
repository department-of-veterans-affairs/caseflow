import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import SearchableDropdown from './SearchableDropdown';
import ApiUtil from '../util/ApiUtil';
import { onReceiveRegionalOffices } from './common/actions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';

class RoSelectorDropdown extends React.Component {

  loadRegionalOffices = () => {
    return ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveRegionalOffices(resp.regionalOffices);
      this.regionalOfficeOptions();
    });
  };

  componentWillMount() {
    if (!this.props.regionalOffices) {
      this.loadRegionalOffices();
    }
  }

  regionalOfficeOptions = () => {

    let regionalOfficeDropdowns = [];

    _.forEach(this.props.regionalOffices, (value, key) => {
      regionalOfficeDropdowns.push({
        label: `${value.city}, ${value.state}`,
        value: key
      });
    });

    if (this.props.staticOptions) {
      regionalOfficeDropdowns.push(...this.props.staticOptions);
    }

    return _.orderBy(regionalOfficeDropdowns, (ro) => ro.label, 'asc');
  };

  render() {
    return <SearchableDropdown
      name="ro"
      label="Regional Office"
      options={this.regionalOfficeOptions()}
      staticOptions={this.props.staticOptions}
      onChange={this.props.onChange}
      value={this.props.value}
      placeholder={this.props.placeholder}
    />;
  }
}

RoSelectorDropdown.propTypes = {
  regionalOffices: PropTypes.object,
  onChange: PropTypes.func,
  value: PropTypes.object,
  placeholder: PropTypes.string,
  staticOptions: PropTypes.array
};

const mapStateToProps = (state) => ({
  regionalOffices: state.components.regionalOffices
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveRegionalOffices
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(RoSelectorDropdown);
