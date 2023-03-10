/* eslint-disable id-length */
import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';
import { GUEST_LINK_LABELS } from '../../constants';

export const DailyDocketGuestLinkSection = ({ linkInfo }) => {

  // Conference Link Information
  const { alias, guestLink, guestPin } = linkInfo || {};

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
    justifyContent: 'space-around'
  };

  // Props needed for the copy text button component
  const CopyTextButtonProps = {
    text: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    label: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    textToCopy: guestLink
  };

  /**
   * Render information about the guest link
   * @param {conferenceRoom} - The conference link alias
   * @param {pin} - The guest pin
   * @param {roleAccess} - Boolean for if the current user has access to the guest link
   * @returns The room information
  */
  const renderRoomInfo = (conferenceRoom, pin) => {
    return (
      <div style={roomInfoContainerStyle}>
        <h3>{GUEST_LINK_LABELS.GUEST_CONFERENCE_ROOM}:<span style={{ fontWeight: 'normal' }}>{conferenceRoom}</span></h3>
        <h3>{GUEST_LINK_LABELS.GUEST_PIN}:<span style={{ fontWeight: 'normal' }}>{pin}#</span></h3>
        <h3><CopyTextButton {...CopyTextButtonProps} /></h3>
      </div>
    );
  };

  return (
    <div style={containerStyle}>
      <h3>{GUEST_LINK_LABELS.GUEST_LINK_SECTION_LABEL}</h3>
      {renderRoomInfo(alias, guestPin)}
    </div>
  );
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
};
