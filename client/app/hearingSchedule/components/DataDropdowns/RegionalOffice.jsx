import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from './actions';
import ApiUtil from '../../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../../../components/SearchableDropdown';

class RegionalOfficeDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getRegionalOffices, 0);
  }

  getRegionalOffices = () => {
    const { regionalOffices: { options, isFetching } } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData('regionalOffices');

    ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      let regionalOfficeOptions = [];

      _.forEach(resp.regionalOffices, (value, key) => {
        regionalOfficeOptions.push({
          label: `${value.city}, ${value.state}`,
          value: key
        });
      });

      regionalOfficeOptions.sort((first, second) => (first.label - second.label));

      this.props.onReceiveDropdownData('regionalOffices', regionalOfficeOptions);
    });
  }

  componentDidUpdate() {
    const { regionalOffices: { options }, value, onChange } = this.props;

    if (options && typeof (value) === 'string') {
      onChange(this.getValue());
    }
  }

  getValue = () => {
    const { value, regionalOffices: { options } } = this.props;

    if (!value) {
      return null;
    }

    return _.find(options, (opt) => opt.value === value);
  }

  render() {
    const { name, label, onChange } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        value={this.getValue()}
        onChange={onChange}
        options={this.props.regionalOffices.options} />
    );
  }
}

RegionalOfficeDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired
};

RegionalOfficeDropdown.defaultProps = {
  name: 'regionalOffice',
  label: 'Regional Office'
};

const mapStateToProps = (state) => ({
  regionalOffices: {
    options: state.hearingDropdownData.regionalOffices.options,
    isFetching: state.hearingDropdownData.regionalOffices.isFetching
  }
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RegionalOfficeDropdown);
