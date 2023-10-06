/* eslint-disable id-length */
import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';
import { GUEST_LINK_LABELS } from '../../constants';

export const DailyDocketGuestLinkSection = ({ linkInfo }) => {
  const containerStyle = {
    marginLeft: '-40px',
    marginRight: '-40px',
  };

  const roomInfoStyle = (index) => ({
    backgroundColor: index === 0 ? '#f1f1f1' : 'white',
    justifyContent: 'space-between',
    display: 'flex',
    width: '100%',
    height: '50px',
  });

  // Props needed for the copy text button component
  const CopyTextButtonProps = {
    text: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    label: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    textToCopy: '',
  };

  // Takes pin from guestLink
  // const usePinFromLink = () => guestLink?.match(/pin=\d+/)[0]?.split('=')[1];
  // Takes alias from guestLink
  const useAliasFromLink = (link) => {
    if (link.type === 'PexipConferenceLink') {
      return (
        link.alias || link.guestLink?.match(/pin=\d+/)[0]?.split('=')[1] || null
      );
    } else if (link.type === 'WebexConferenceLink') {
      const newLink = 'instant-usgov';

      return link.alias || newLink || null;
    }

    return null;
  };

  const extractPin = (link) => {
    if (link.type === 'PexipConferenceLink') {
      return `${link.guestPin}#` || `${link.guestLink?.match(/pin=(\d+)/)?.[1]}#`;
    } else if (link.type === 'WebexConferenceLink') {
      return 'N/A';
    }

    return null;
  };

  /**
   * Render information about the guest link
   * @param {conferenceRoom} - The conference link alias
   * @param {pin} - The guest pin
   * @param {roleAccess} - Boolean for if the current user has access to the guest link
   * @returns The room information
   */
  const renderRoomInfo = () => {
    return (
      <div>
        {Object.values(linkInfo).map((link, index) => {
          const { guestLink, type } = link;

          CopyTextButtonProps.textToCopy = guestLink;

          const alias = useAliasFromLink(link);
          const linkGuestPin = extractPin(link);

          return (
            <div key={index} style={roomInfoStyle(index)}>
              <h3
                style={{
                  width: '350px',
                  display: 'flex',
                  marginBottom: '0px',
                  alignItems: 'center',
                  marginLeft: '10px',
                }}
              >
                {type === 'PexipConferenceLink' ?
                  GUEST_LINK_LABELS.PEXIP_GUEST_LINK_SECTION_LABEL :
                  GUEST_LINK_LABELS.WEBEX_GUEST_LINK_SECTION_LABEL}
              </h3>

              <h3
                style={{
                  display: 'flex',
                  marginBottom: '0px',
                  alignItems: 'center',
                  width: '400px',
                }}
              >
                {GUEST_LINK_LABELS.GUEST_CONFERENCE_ROOM}
                <span style={{ fontWeight: 'normal' }}>{alias || 'N/A'}</span>
              </h3>
              <h3
                style={{
                  width: 'max-content',
                  display: 'flex',
                  alignItems: 'center',
                  marginBottom: '0px',
                }}
              >
                {GUEST_LINK_LABELS.GUEST_PIN}
                {linkGuestPin ? (
                  <span
                    style={{
                      fontWeight: 'normal',
                      paddingRight: '10px',
                      display: 'flex',
                    }}
                  >
                    {linkGuestPin}
                  </span>
                ) : (
                  <span
                    style={{
                      fontWeight: 'normal',
                      paddingRight: '60px',
                      display: 'flex',
                    }}
                  >
                    N/A
                  </span>
                )}
              </h3>
              <h3
                style={{

                  display: 'flex',
                  alignItems: 'center',
                  marginBottom: '0px',
                  marginRight: '10px',
                }}
              >
                <CopyTextButton {...CopyTextButtonProps} />
              </h3>
            </div>
          );
        })}
      </div>
    );
  };

  return <div style={containerStyle}>{renderRoomInfo()}</div>;
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
};

