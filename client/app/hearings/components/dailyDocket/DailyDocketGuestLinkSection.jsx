/* eslint-disable id-length */
import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';

export const DailyDocketGuestLinkSection = ({ linkInfo, requestType, hasAccess }) => {

  // Conference Link Information
  const { alias, guestLink, guestPin } = linkInfo;

  // The hearing type that the guest link is for
  const hearingType = {
    C: 'central hearings',
    V: 'non-virtual hearings',
    T: 'travel hearings',
  };

  const containerStyle = {
    display: 'grid',
    gridTemplateColumns: '1fr 1.8fr',
    backgroundColor: '#f1f1f1',
    padding: '1em 0 0 1em',
    marginLeft: '-40px',
    marginRight: '-40px'
  };

  const roomInfoContainerStyle = {
    display: 'flex',
    flexWrap: 'wrap',
    fontSize: '12px',
    justifyContent: 'space-around'
  };

  // Props needed for the copy text button component
  const CopyTextButtonProps = {
    text: 'Copy Guest Link',
    label: 'Copy Guest Link',
    textToCopy: guestLink
  };

  /**
   * Render information about the guest link
   * @param {conferenceRoom} - The conference link alias
   * @param {pin} - The guest pin
   * @param {roleAccess} - Boolean for if the current user has access to the guest link
   * @returns The room information
  */
  const renderRoomInfo = (conferenceRoom, pin, roleAccess) => {
    return (
      <div style={roomInfoContainerStyle}>
        <h3>Conference Room:<span style={{ fontWeight: 'normal' }}>{conferenceRoom}</span></h3>
        <h3>PIN:<span style={{ fontWeight: 'normal' }}>{pin}#</span></h3>
        {roleAccess && <h3><CopyTextButton {...CopyTextButtonProps} /></h3>}
      </div>
    );
  };

  return (
    <div style={containerStyle}>
      <h3>Guest links for {hearingType[requestType] || hearingType.V}</h3>
      {renderRoomInfo(alias, guestPin, hasAccess)}
    </div>
  );
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
  hasAccess: PropTypes.bool.isRequired,
  requestType: PropTypes.string
};
