import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import LoadingLabel from './LoadingLabel';
import HEARING_REQUEST_TYPES from '../../../constants/HEARING_REQUEST_TYPES';
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
    const {
      excludeVirtualHearingsOption,
      regionalOffices: { options, isFetching }
    } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData('regionalOffices');

    ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      let regionalOfficeOptions = [];

      _.forEach(
        resp.regionalOffices,
        (value, key) => {
          let label;

          if (!value.state && !value.city) {
            label = value.label;
          } else {
            label = value.state === 'DC' ? 'Central' : `${value.city}, ${value.state}`;
          }

          if (key === HEARING_REQUEST_TYPES['virtual'] && excludeVirtualHearingsOption) {
            return;
          }

          regionalOfficeOptions.push({
            label,
            value: { key, ...value }
          });
        }
      );

      regionalOfficeOptions.sort((first, second) => (first.label < second.label ? -1 : 1));

      this.props.onReceiveDropdownData('regionalOffices', regionalOfficeOptions);
    });
  }

  getSelectedOption = () => {
    const { value, regionalOffices: { options } } = this.props;

    return _.find(options, (opt) => opt.value.key === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const {
      name, label, onChange,
      regionalOffices: { options, isFetching },
      readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={isFetching ? <LoadingLabel text="Loading regional offices..." /> : label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange((option || {}).value, (option || {}).label)}
        options={options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

RegionalOfficeDropdown.propTypes = {
  errorMessage: PropTypes.string,

  // Whether or not to hide the "Virtual Hearings" option from the dropdown.
  excludeVirtualHearingsOption: PropTypes.bool,

  label: PropTypes.string,
  name: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  onFetchDropdownData: PropTypes.func.isRequired,
  onReceiveDropdownData: PropTypes.func.isRequired,
  placeholder: PropTypes.string,
  readOnly: PropTypes.bool,
  regionalOffices: PropTypes.shape({
    options: PropTypes.arrayOf(PropTypes.object),
    isFetching: PropTypes.bool
  }),
  validateValueOnMount: PropTypes.bool,

  // Regional Office Key
  value: PropTypes.string
};

RegionalOfficeDropdown.defaultProps = {
  excludeVirtualHearingsOption: false,
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
