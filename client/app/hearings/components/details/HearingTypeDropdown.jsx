import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';

class HearingTypeDropdown extends React.Component {

  constructor (props) {
    super(props);

    const { requestType } = props;

    this.HEARING_TYPE_OPTIONS = [
      {
        value: false,
        label: requestType
      },
      {
        value: true,
        label: 'Virtual'
      }
    ];
  }

  getValue = () => {
    const { virtualHearing } = this.props;

    if (!virtualHearing || !virtualHearing.status || virtualHearing.status === 'cancelled') {
      return this.HEARING_TYPE_OPTIONS[0];
    }

    return this.HEARING_TYPE_OPTIONS[1];
  }

  onChange = (option) => {
    const { updateVirtualHearing, openModal } = this.props;
    const currentValue = this.getValue();

    // if current value is true (a virtual hearing), then we will be sending cancellation emails,
    // if new value is true, then we will be sending confirmation emails
    if ((currentValue.value || option.value) && currentValue.value !== option.value) {
      const type = option.value ? 'change_to_virtual' : 'change_from_virtual';

      openModal({ type });
    }

    if (currentValue.value && !option.value) {
      updateVirtualHearing({ status: 'cancelled' });
    }
  }

  render () {
    return (
      <SearchableDropdown
        label="Hearing Type"
        name="hearingType"
        strongLabel
        options={this.HEARING_TYPE_OPTIONS}
        value={this.getValue()}
        onChange={this.onChange}
        readOnly={this.props.readOnly}
        styling={this.props.styling}
      />
    );
  }
}

HearingTypeDropdown.propTypes = {
  virtualHearing: PropTypes.object,
  updateVirtualHearing: PropTypes.func,
  openModal: PropTypes.func,
  requestType: PropTypes.string,
  readOnly: PropTypes.bool,
  styling: PropTypes.object
};

export default HearingTypeDropdown;
