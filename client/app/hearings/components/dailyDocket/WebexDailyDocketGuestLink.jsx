/* eslint-disable id-length */
import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';
import { GUEST_LINK_LABELS } from '../../constants';

export const WebexDailyDocketGuestLink = ({ linkInfo }) => {
  // Conference Link Information
  const { alias, guestLink, guestPin } = linkInfo || {};

  const containerStyle = {
    display: 'grid',
    gridTemplateColumns: '1fr 1.8fr',
    backgroundColor: 'white',
    padding: '1em 0 0 1em',
    marginLeft: '-40px',
    marginRight: '-40px',
    marginBottom: '20px',
  };

  const roomInfoContainerStyle = {
    display: 'flex',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    paddingLeft: '40px',
    paddingRight: '40px',
  };

  // Props needed for the copy text button component
  const CopyTextButtonProps = {
    text: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    label: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    textToCopy: guestLink,
  };

  // Takes pin from guestLink
  const usePinFromLink = () => guestLink?.match(/pin=\d+/)[0]?.split('=')[1];
  // Takes alias from guestLink
  const useAliasFromLink = () =>
    guestLink
      ?.split('&')[0]
      ?.match(/conference=.+/)[0]
      ?.split('=')[1];

  const linkIsPresent = linkInfo;
  const buttonDisabled = true;

  /**
   * Render information about the guest link
   * @param {conferenceRoom} - The conference link alias
   * @param {pin} - The guest pin
   * @param {roleAccess} - Boolean for if the current user has access to the guest link
   * @returns The room information
   */
  const renderRoomInfo = () => {
    return (
      <div style={roomInfoContainerStyle}>
        <h3>
          {GUEST_LINK_LABELS.GUEST_CONFERENCE_ROOM}:
          {linkIsPresent ? (
            <span style={{ fontWeight: 'normal' }}>
              {alias || useAliasFromLink()}
            </span>
          ) : (
            <span style={{ fontWeight: 'normal' }}>N/A</span>
          )}
        </h3>
        {linkIsPresent ? (
          <>
            <h3>
              {GUEST_LINK_LABELS.GUEST_PIN}:
              <span style={{ fontWeight: 'normal' }}>{usePinFromLink()}#</span>
            </h3>
            <h3>
              <CopyTextButton {...CopyTextButtonProps} />
            </h3>
          </>
        ) : (
          <>
            <h3 style={{ paddingLeft: '130px' }}>
              {GUEST_LINK_LABELS.GUEST_PIN}:
              <span style={{ fontWeight: 'normal' }}>N/A</span>
            </h3>
            <h3>
              <CopyTextButton {...CopyTextButtonProps} disabled={buttonDisabled} />
            </h3>
          </>
        )}
      </div>
    );
  };

  return (
    <div style={containerStyle}>
      <h3>{GUEST_LINK_LABELS.WEBEX_GUEST_LINK_SECTION_LABEL}</h3>
      {renderRoomInfo(alias, guestPin)}
    </div>
  );
};

WebexDailyDocketGuestLink.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
};
