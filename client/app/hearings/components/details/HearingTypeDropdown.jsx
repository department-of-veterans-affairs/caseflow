import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';

class HearingTypeDropdown extends React.Component {
  constructor(props) {
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
  };

  onChange = ({ value, label }) => {
    const { convertHearing, update, openModal } = this.props;
    const { value: currentValue, label: currentLabel } = this.getValue();

    // Don't change if the value is the same
    if (label === currentLabel) {
      return;
    }

    // if current value is true (a virtual hearing), then we will be sending cancellation emails,
    // if new value is true, then we will be sending confirmation emails
    const type = value && currentValue !== value ? 'change_to_virtual' : 'change_from_virtual';

    // Use the modal if the label is video
    if ((label === 'Video' || currentLabel === 'Video')) {
      openModal({ type });

      // If the current value is not virtual, we are cancelling the virtual hearing
      update('virtualHearing', { requestCancelled: currentLabel === 'Virtual', jobCompleted: false });
    } else {
      convertHearing(type);
    }
  };

  render() {
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
  update: PropTypes.func,
  openModal: PropTypes.func,
  convertHearing: PropTypes.func,
  requestType: PropTypes.string,
  readOnly: PropTypes.bool,
  styling: PropTypes.object
};

export default HearingTypeDropdown;
