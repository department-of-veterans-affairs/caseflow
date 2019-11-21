import React from 'react';
import PropTypes from 'prop-types';

import VirtualHearingModal from './VirtualHearingModal';
import DetailsInputs from './details/DetailsInputs';
import TranscriptionDetailsInputs from './details/TranscriptionDetailsInputs';
import TranscriptionProblemInputs from './details/TranscriptionProblemInputs';
import TranscriptionRequestInputs from './details/TranscriptionRequestInputs';

class DetailsSections extends React.Component {

  constructor (props) {
    super(props);

    this.state = {
      modalOpen: false
    };
  }

  openModal = ({ modalTitle, modalIntro, modalButton}) => this.setState({
    modalOpen: true,
    modalTitle: modalTitle,
    modalIntro: modalIntro,
    modalButton: modalButton,
  })
  closeModal = () => this.setState({ modalOpen: false })

  resetVirtualHearing = () => {
    const { initialHearingState: { virtualHearing } } = this.props;

    if (virtualHearing) {
      this.props.updateVirtualHearing(virtualHearing);
    } else {
      this.props.updateVirtualHearing(null);
    }

    this.closeModal();
  }

  render () {
    const {
      transcription, hearing, disabled, updateHearing, updateTranscription, updateVirtualHearing,
      isLegacy, virtualHearing, submit, user, initialHearingState, requestType
    } = this.props;
    const { modalOpen, modalTitle, modalIntro, modalButton} = this.state;

    return (
      <React.Fragment>
        <DetailsInputs
          readOnly={disabled}
          requestType={requestType}
          isLegacy={isLegacy}
          hearing={hearing}
          update={updateHearing}
          enableVirtualHearings={user.userCanScheduleVirtualHearings && requestType !== 'Central'}
          virtualHearing={virtualHearing}
          updateVirtualHearing={updateVirtualHearing}
          openModal={this.openModal}
          openVirtualHearingModal={this.openModal} />
        <div className="cf-help-divider" />
        {modalOpen && <VirtualHearingModal
          hearing={initialHearingState}
          virtualHearing={virtualHearing}
          update={updateVirtualHearing}
          submit={() => submit().then(this.closeModal)}
          reset={this.resetVirtualHearing}
          modalTitle={modalTitle}
          modalIntro={modalIntro}
          modalButton={modalButton}
          showTimeAndLocation={true}/>}
        {!isLegacy &&
          <div>
            <h2>Transcription Details</h2>
            <TranscriptionDetailsInputs
              transcription={transcription}
              update={updateTranscription}
              readOnly={disabled} />
            <div className="cf-help-divider" />

            <h2>Transcription Problem</h2>
            <TranscriptionProblemInputs
              transcription={transcription}
              update={updateTranscription}
              readOnly={disabled} />
            <div className="cf-help-divider" />

            <h2>Transcription Request</h2>
            <TranscriptionRequestInputs
              hearing={hearing}
              update={updateHearing}
              readOnly={disabled} />
            <div className="cf-help-divider" />
          </div>
        }
      </React.Fragment>
    );
  }
}

DetailsSections.propTypes = {
  transcription: PropTypes.object,
  hearing: PropTypes.object,
  virtualHearing: PropTypes.object,
  initialHearingState: PropTypes.shape({
    virtualHearing: PropTypes.shape({
      veteranEmail: PropTypes.string,
      representativeEmail: PropTypes.string,
      status: PropTypes.string
    })
  }),
  disabled: PropTypes.bool,
  updateHearing: PropTypes.func,
  updateTranscription: PropTypes.func,
  updateVirtualHearing: PropTypes.func,
  isLegacy: PropTypes.bool,
  requestType: PropTypes.string,
  submit: PropTypes.func,
  user: PropTypes.shape({
    userCanScheduleVirtualHearings: PropTypes.bool
  })
};

// These props are set through Redux
// set default values for time between mount
// and redux state being set
DetailsSections.defaultProps = {
  hearing: {},
  transcription: {}
};

export default DetailsSections;
