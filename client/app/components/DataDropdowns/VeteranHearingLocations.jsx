import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
// import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';

import SearchableDropdown from '../SearchableDropdown';

const generateHearingLocationOptions = (hearingLocations) => (
  hearingLocations.map((location) => ({
    label: `${location.city}, ${location.state} (${location.distance} miles away)`,
    value: {
      name: location.name,
      address: location.address,
      city: location.city,
      state: location.state,
      zipCode: location.zipCode,
      distance: location.distance,
      classification: location.classification,
      facilityId: location.facilityId,
      facilityType: location.facilityType
    }
  }))
);

class VeteranHearingLocationsDropdown extends React.Component {

  componentDidMount() {
    if (this.props.dynamic || !this.props.staticHearingLocations) {
      setTimeout(this.getLocations, 0);
    } else {
      this.props.onReceiveDropdownData(
        `hearingLocationsFor${this.props.veteranFileNumber}`,
        generateHearingLocationOptions(this.props.staticHearingLocations)
      );
    }
  }

  componentDidUpdate(prevProps) {
    const { dynamic, regionalOffice } = this.props;

    if ((prevProps.dynamic !== dynamic || prevProps.regionalOffice !== regionalOffice) && dynamic) {
      setTimeout(this.getLocations, 0);
    }
  }

  getLocations = () => {
    const { veteranHearingLocations: { options, isFetching }, veteranFileNumber } = this.props;

    const name = `hearingLocationsFor${veteranFileNumber}`;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData(name);

    // TODO Dynamic Location Loading
    // ApiUtil.get('').then((resp) => {
    //   const locationOptions = _.values(ApiUtil.convertToCamelCase(resp.body.hearingLocations)).map((loc) => ({
    //
    //   }));
    //
    //   locationOptions.sort((first, second) => (first.distance - second.distance));
    //
    //   this.props.onReceiveDropdownData(name, locationOptions);
    // });
  }

  getSelectedOption = () => {
    const { value, veteranHearingLocations: { options } } = this.props;

    if (typeof (value) === 'string') {
      return _.find(options, (opt) => opt.value.facilityId === value) ||
        {
          value: null,
          label: null
        };
    }

    return _.find(options, (opt) => opt.value === value) ||
      {
        value: null,
        label: null
      };
  }

  render() {
    const { name, label, onChange, readOnly, errorMessage, placeholder } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value, option.label)}
        options={this.props.veteranHearingLocations.options}
        errorMessage={errorMessage}
        placeholder={placeholder} />
    );
  }
}

VeteranHearingLocationsDropdown.propTypes = {
  veteranFileNumber: PropTypes.string.isRequired,
  staticHearingLocations: PropTypes.array,
  regionalOffice: PropTypes.string,
  name: PropTypes.string,
  label: PropTypes.string,
  dynamic: PropTypes.bool,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

VeteranHearingLocationsDropdown.defaultProps = {
  name: 'veteranHearingLocation',
  label: 'Hearing Location'
};

const mapStateToProps = (state, props) => ({
  veteranHearingLocations: state.components.dropdowns[`hearingLocationsFor${props.veteranFileNumber}`] ? {
    options: state.components.dropdowns[`hearingLocationsFor${props.veteranFileNumber}`].options,
    isFetching: state.components.dropdowns[`hearingLocationsFor${props.veteranFileNumber}`].isFetching
  } : {}
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(VeteranHearingLocationsDropdown);
