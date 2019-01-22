import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../SearchableDropdown';

class RegionalOfficeDropdown extends React.Component {

  componentDidMount() {
    setTimeout(this.getRegionalOffices, 0);
  }

  componentDidUpdate(prevProps) {
    const { regionalOffices: { options }, validateValueOnMount, onChange } = this.props;

    if (!_.isEqual(prevProps.regionalOffices.options, options) && validateValueOnMount) {
      const option = this.getSelectedOption();

      onChange(option.value, option.label);
    }
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
          label: value.state === 'DC' ? 'Central' : `${value.city}, ${value.state}`,
          value: key
        });
      });

      regionalOfficeOptions.sort((first, second) => (first.label - second.label));

      this.props.onReceiveDropdownData('regionalOffices', regionalOfficeOptions);
    });
  }

  getSelectedOption = () => {
    const { value, regionalOffices: { options } } = this.props;

    return _.find(options, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const { name, label, onChange, regionalOffices: { options }, readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value, option.label)}
        options={options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

RegionalOfficeDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string,
  // run onChange when dropdown mounts
  validateValueOnMount: PropTypes.bool
};

RegionalOfficeDropdown.defaultProps = {
  name: 'regionalOffice',
  label: 'Regional Office'
};

const mapStateToProps = (state) => ({
  regionalOffices: state.components.dropdowns.regionalOffices ? {
    options: state.components.dropdowns.regionalOffices.options,
    isFetching: state.components.dropdowns.regionalOffices.isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(RegionalOfficeDropdown);
