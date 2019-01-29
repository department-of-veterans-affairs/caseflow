import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { onReceiveDropdownData, onFetchDropdownData } from '../common/actions';
import ApiUtil from '../../util/ApiUtil';
import { css } from 'glamor';
import _ from 'lodash';
import { loadingSymbolHtml } from '../RenderFunctions';

import SearchableDropdown from '../SearchableDropdown';

export const getFacilityType = (location) => {
  switch (location.facilityType) {
  case 'vet_center':
    return '(Vet Center) ';
  case 'va_health_facility':
    return '(VHA) ';
  case 'va_benefits_facility':
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

class VeteranHearingLocationsDropdown extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      errorMsg: false
    };
  }

  componentDidMount() {
    const { dropdownName, dynamic, staticHearingLocations } = this.props;

    if (dynamic || !staticHearingLocations) {
      setTimeout(this.getLocations, 0);
    } else {
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
      veteranHearingLocations: { options, isFetching },
      veteranFileNumber, regionalOffice, dropdownName
    } = this.props;

    if (options || isFetching) {
      return;
    }

    this.props.onFetchDropdownData(name);

    let url = '/hearings/find_closest_hearing_locations?regional_office=';

    url += `${regionalOffice}&veteran_file_number=${veteranFileNumber}`;

    ApiUtil.get(url).then((resp) => {
      const locationOptionsResp = _.values(ApiUtil.convertToCamelCase(resp.body).hearingLocations);
      const locationOptions = generateHearingLocationOptions(locationOptionsResp);

      locationOptions.sort((first, second) => (first.distance - second.distance));

      this.props.onReceiveDropdownData(dropdownName, locationOptions);
      this.setState({ errorMsg: false });
    }).
      catch((error) => {

        let errorReason = '.';

        if (error.body.message.messages && error.body.message.messages[0]) {
          switch (error.body.message.messages[0].key) {
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
        }

        const errorMsg = `
          Could not find hearing locations for this veteran${errorReason}
        `;

        this.props.onReceiveDropdownData(dropdownName, []);
        this.setState({ errorMsg });
      });
  }

  getSelectedOption = () => {
    const { value, veteranHearingLocations: { options } } = this.props;

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
      veteranHearingLocations: { isFetching } } = this.props;

    return (
      <div>
        {isFetching &&
          <span {...css({
            marginTop: '-25px',
            '& > *': {
              display: 'inline-block',
              marginRight: '10px'
            }
          })}>
            {loadingSymbolHtml('', '15px')}
            {'Finding hearing locations for veteran ...'}
          </span>
        }
        <SearchableDropdown
          name={name}
          label={label}
          strongLabel
          readOnly={readOnly}
          value={this.getSelectedOption()}
          onChange={(option) => onChange(option.value, option.label)}
          options={this.props.veteranHearingLocations.options}
          errorMessage={this.state.errorMsg || errorMessage}
          placeholder={placeholder} />
      </div>
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

const mapStateToProps = (state, props) => {
  const { regionalOffice, veteranFileNumber } = props;
  const name = `hearingLocationsFor${veteranFileNumber}At${regionalOffice}`;

  return {
    dropdownName: name,
    veteranHearingLocations: state.components.dropdowns[name] ? {
      options: state.components.dropdowns[name].options,
      isFetching: state.components.dropdowns[name].isFetching
    } : {}
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onFetchDropdownData,
  onReceiveDropdownData
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(VeteranHearingLocationsDropdown);
