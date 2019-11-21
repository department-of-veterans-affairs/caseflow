import React from 'react';
import PropTypes from 'prop-types';
import SearchableDropdown from '../../../components/SearchableDropdown';
import COPY from '../../../../COPY.json';

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

  getModalTitleAndIntro = (option) => {
    if (option.value) {
      return {
        modalTitle: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE,
        modalIntro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_INTRO 
      };
    }
    if (option.label === 'Video') {
      return {
        modalTitle: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_TITLE,
        modalIntro: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_VIDEO_INTRO 
      };
    } else {
      return {
        modalTitle: COPY.VIRTUAL_HEARING_MODAL_CHANGE_TO_CENTRAL_TITLE,
        modalIntro: ''
      };
    }
  }

  onChange = (option) => {
    const { updateVirtualHearing, openModal } = this.props;
    const currentValue = this.getValue();

    // if current value is true (a virtual hearing), then we will be sending cancellation emails,
    // if new value is true, then we will be sending confirmation emails
    if (currentValue.value || option.value) {
      const { modalTitle, modalIntro } = this.getModalTitleAndIntro(option);
      openModal({
        modalTitle: modalTitle,
        modalIntro: modalIntro,
        modalButton: COPY.VIRTUAL_HEARING_CHANGE_HEARING_BUTTON
      });
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
      />
    );
  }
}

HearingTypeDropdown.propTypes = {
  virtualHearing: PropTypes.object,
  updateVirtualHearing: PropTypes.func,
  openModal: PropTypes.func,
  requestType: PropTypes.string
};

export default HearingTypeDropdown;
