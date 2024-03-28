import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';
import { GUEST_LINK_LABELS } from '../../constants';

const H3Styled = ({ children, style }) => (
  <h3
    style={{
      marginBottom: '0px',
      display: 'flex',
      alignItems: 'center',
      ...style,
    }}
  >
    {children}
  </h3>
);

const SpanStyled = ({ children }) => (
  <span
    style={{
      fontWeight: 'normal',
      paddingRight: '10px',
      display: 'flex',
      marginLeft: '5px',
    }}
  >
    {children}
  </span>
);

const ConferenceRoom = ({ type, alias }) => (
  <H3Styled
    style={{ width: type === 'PexipConferenceLink' ? '415px' : '550px' }}
  >
    {type === 'PexipConferenceLink' ?
      GUEST_LINK_LABELS.PEXIP_GUEST_CONFERENCE_ROOM :
      GUEST_LINK_LABELS.WEBEX_GUEST_CONFERENCE_ROOM}
    <SpanStyled>{alias || 'N/A'}</SpanStyled>
  </H3Styled>
);

export const DailyDocketGuestLinkSection = ({ linkInfo }) => {
  const containerStyle = {
    marginLeft: '-40px',
    marginRight: '-40px',
    marginTop: '20px',
    marginBottom: '75px'
  };

  const roomInfoStyle = (index) => ({
    backgroundColor: index === 0 ? '#f1f1f1' : 'white',
    justifyContent: 'space-between',
    display: 'flex',
    width: '100%',
    height: '50px',
    marginBottom: '20px',
    marginTop: '20px',
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
      const webexGuestLink = link.guestLink;

      return link.alias || webexGuestLink || null;
    }

    return null;
  };

  const extractPin = (link) => {
    if (link.type === 'PexipConferenceLink') {
      return `${link.guestPin}#`;
    } else if (link.type === 'WebexConferenceLink') {
      return null;
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
  const renderRoomInfo = () => (
    <div>
      {linkInfo &&
        Object.values(linkInfo).map((link, index) => {
          const { guestLink, type } = link;

          CopyTextButtonProps.textToCopy = guestLink;

          const alias = useAliasFromLink(link);
          const linkGuestPin = extractPin(link);

          return (
            <div key={index} style={roomInfoStyle(index)}>
              <H3Styled style={{ width: '350px', marginLeft: '40px' }}>
                {type === 'PexipConferenceLink' ?
                  GUEST_LINK_LABELS.PEXIP_GUEST_LINK_SECTION_LABEL :
                  GUEST_LINK_LABELS.WEBEX_GUEST_LINK_SECTION_LABEL}
              </H3Styled>

              <ConferenceRoom type={type} alias={alias} />

              <H3Styled style={{ width: 'max-content', marginRight: '75px' }}>
                {type === 'PexipConferenceLink' && GUEST_LINK_LABELS.GUEST_PIN}
                <SpanStyled>{linkGuestPin}</SpanStyled>
              </H3Styled>

              <H3Styled style={{ marginRight: '20px' }}>
                <CopyTextButton {...CopyTextButtonProps} />
              </H3Styled>
            </div>
          );
        })}
    </div>
  );

  return <div style={containerStyle}>{renderRoomInfo()}</div>;
};

H3Styled.propTypes = {
  children: PropTypes.node,
  style: PropTypes.object,
};

SpanStyled.propTypes = {
  children: PropTypes.node,
};

ConferenceRoom.propTypes = {
  type: PropTypes.string,
  alias: PropTypes.string,
  children: PropTypes.node,
  style: PropTypes.object,
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.arrayOf(
    PropTypes.shape({
      guestLink: PropTypes.string,
      guestPin: PropTypes.string,
      alias: PropTypes.string,
      type: PropTypes.string,
    })
  ),
};
