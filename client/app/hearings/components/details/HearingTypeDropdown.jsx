import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';

class HearingTypeDropdown extends React.PureComponent {

  constructor (props) {
    super(props);

    const { requestType, virtualHearing } = props;

    // This component should work with either a Video or Central hearing.
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

    // A hearing is virtual if the virtual hearing is not set, or the status
    // is cancelled.
    const isVirtual = (
      virtualHearing 
        && virtualHearing.status 
        && virtualHearing.status !== 'cancelled'
    );
    const initialState = this.getHearingTypeOption(isVirtual);

    this.state = {
      value: initialState
    };
  }

  getHearingTypeOption = (value) => (
    value ? this.HEARING_TYPE_OPTIONS[1] : this.HEARING_TYPE_OPTIONS[0]
  );

  onChange = (option) => {
    const { updateVirtualHearing, openModal } = this.props;

    const { value: currentValue } = this.state;
    const newValue = this.getHearingTypeOption(option.value);

    // Value is not changing.
    if (currentValue.value === newValue.value) {
      return;
    }

    this.setState({ value: newValue });

    // Value is changing.
    //
    // if current value is true (a virtual hearing), then we will be sending cancellation emails,
    // if new value is true, then we will be sending confirmation emails
    if (currentValue.value !== newValue.value) {
      const type = newValue.value ? 'change_to_virtual' : 'change_from_virtual';

      openModal({ type });
    }

    // If the currentValue is true, that means the hearing is current a virtual hearing.
    // If newValue is false, that means that the user selected the original request type.
    const changeFromVirtualToVideo = currentValue.value && !newValue.value;

    if (changeFromVirtualToVideo) {
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
        value={this.state.value}
        onChange={this.onChange}
        readOnly={this.props.readOnly}
      />
    );
  }
}

HearingTypeDropdown.propTypes = {
  virtualHearing: PropTypes.object,
  updateVirtualHearing: PropTypes.func,
  openModal: PropTypes.func,
  requestType: PropTypes.string,
  readOnly: PropTypes.bool
};

export default HearingTypeDropdown;
