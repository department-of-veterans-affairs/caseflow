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

  onChange = ({ label }) => {
    const { convertHearing, update, openModal, enableFullPageConversion } = this.props;
    const { label: currentLabel } = this.getValue();

    // Change from virtual if the current label is virtual
    const type = currentLabel === 'Virtual' ? 'change_from_virtual' : 'change_to_virtual';

    // Use the modal if the label is video
    if ((label === 'Video' || currentLabel === 'Video') && !enableFullPageConversion) {
      openModal({ type });
    } else {
      convertHearing(type);
    }

    // If the current value is not virtual, we are cancelling the virtual hearing
    update('virtualHearing', { requestCancelled: currentLabel === 'Virtual', jobCompleted: false });
  };

  render() {
    return (
      <SearchableDropdown
        label="Hearing Type"
        name="hearingType"
        strongLabel
        options={this.HEARING_TYPE_OPTIONS.filter((opt) => opt.label !== this.getValue().label)}
        value={this.getValue()}
        onChange={this.onChange}
        readOnly={this.props.readOnly}
        styling={this.props.styling}
      />
    );
  }
}

HearingTypeDropdown.propTypes = {
  enableFullPageConversion: PropTypes.bool,
  virtualHearing: PropTypes.object,
  update: PropTypes.func,
  openModal: PropTypes.func,
  convertHearing: PropTypes.func,
  requestType: PropTypes.string,
  readOnly: PropTypes.bool,
  styling: PropTypes.object
};

export default HearingTypeDropdown;
