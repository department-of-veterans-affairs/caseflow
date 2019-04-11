import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  onReceiveDropdownData,
  onFetchDropdownData,
  onDropdownError
} from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';
import LoadingLabel from './LoadingLabel';

import SearchableDropdown from '../SearchableDropdown';

export const getFacilityType = (location) => {
  switch (location.facilityType) {
  case 'vet_center':
    return '(Vet Center) ';
  case 'va_health_facility':
    return '(VHA) ';
  case 'va_benefits_facility':
    if (location.facilityId === 'vba_372') {
      return '(BVA)';
    }

    return location.classification.indexOf('Regional') === -1 ? '(VBA) ' : '(RO) ';
  default:
    return '';
  }
};

const generateHearingLocationOptions = (hearingLocations) => (
  hearingLocations.map((location) => ({
    label: `${location.city}, ${location.state} ${getFacilityType(location)}${location.distance} miles away`,
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

class AppealHearingLocationsDropdown extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      errorMsg: false
    };
  }

  componentDidMount() {
    const { dropdownName, dynamic, staticHearingLocations } = this.props;

    if (dynamic) {
      setTimeout(this.getLocations, 0);
    } else if (staticHearingLocations) {
      this.props.onReceiveDropdownData(
        dropdownName,
        generateHearingLocationOptions(staticHearingLocations)
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
    const {
      appealHearingLocations: { options, isFetching },
      appealId, regionalOffice, dropdownName
    } = this.props;

    if (options || isFetching || _.isUndefined(regionalOffice)) {
      return;
    }

    this.props.onFetchDropdownData(dropdownName);

    let url = '/hearings/find_closest_hearing_locations?regional_office=';

    url += `${regionalOffice}&appeal_id=${appealId}`;

    ApiUtil.get(url).then((resp) => {
      const locationOptionsResp = _.values(ApiUtil.convertToCamelCase(resp.body).hearingLocations);
      const locationOptions = generateHearingLocationOptions(locationOptionsResp);

      locationOptions.sort((first, second) => (first.distance - second.distance));

      this.props.onReceiveDropdownData(dropdownName, locationOptions);
      this.props.onDropdownError(dropdownName, null);
    }).
      catch((error) => {
        let errorReason = '.';

        switch (error.response.body.message) {
        case 'InvalidRequestStreetAddress':
          errorReason = ' because their address does not exist in VBMS.';
          break;
        case 'AddressCouldNotBeFound':
          errorReason = ' because their address from VBMS could not be found on a map.';
          break;
        case 'DualAddressError':
          errorReason = ' because their address from VBMS is ambiguous.';
          break;
        default:
          errorReason = '.';
        }

        const errorMsg = `Could not find hearing locations for this appellant${errorReason}`;

        this.props.onReceiveDropdownData(dropdownName, []);
        this.props.onDropdownError(dropdownName, errorMsg);
      });
  }

  getSelectedOption = () => {
    const { value, appealHearingLocations: { options } } = this.props;

    const facilityId = typeof (value) === 'string' ? value : (value || {}).facilityId;

    return _.find(options, (opt) => opt.value.facilityId === facilityId) ||
      {
        value: null,
        label: null
      };

  }

  render() {
    const {
      name, label, onChange, readOnly, errorMessage, placeholder,
      appealHearingLocations: { isFetching, options } } = this.props;

    return (
      <SearchableDropdown
        name={name}
        label={isFetching ? <LoadingLabel text="Finding hearing locations for veteran ..." /> : label}
        strongLabel
        readOnly={readOnly}
        value={this.getSelectedOption()}
        onChange={(option) => onChange(option.value, option.label)}
        options={options}
        errorMessage={this.state.errorMsg || errorMessage}
        placeholder={placeholder} />
    );
  }
}

AppealHearingLocationsDropdown.propTypes = {
  appealId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
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

AppealHearingLocationsDropdown.defaultProps = {
  name: 'appealHearingLocation',
  label: 'Hearing Location'
};

const mapStateToProps = (state, props) => {
  const { regionalOffice, appealId } = props;
  const name = `hearingLocationsFor${appealId}At${regionalOffice}`;

  return {
    dropdownName: name,
    appealHearingLocations: state.components.dropdowns[name] ? {
      options: _.orderBy(state.components.dropdowns[name].options, ['value.distance'], ['asc']),
      isFetching: state.components.dropdowns[name].isFetching,
      errorMsg: state.components.dropdowns[name].errorMsg
    } : {}
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData,
  onDropdownError
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(AppealHearingLocationsDropdown);
