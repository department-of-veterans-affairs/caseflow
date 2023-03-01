import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';

export const DailyDocketGuestLinkSection = ({ linkInfo }) => {

  const { alias, hostLink, hostPin } = linkInfo;

  const containerStyle = {
    display: 'grid',
    gridTemplateColumns: '1fr 3fr',
    backgroundColor: '#f1f1f1',
    padding: '0.7em 0 0 1em',
  };

  const roomInfoContainerStyle = {
    display: 'flex',
    fontSize: '12px',
    justifyContent: 'space-evenly'
  };

  const CopyTextButtonProps = {
    text: 'Copy Guest Link',
    label: 'Copy Guest Link',
    textToCopy: hostLink
  }

  return (
    <div style={containerStyle}>
      <h3>Guest links for non-virtual hearings</h3>
      <div style={roomInfoContainerStyle}>
        <h3>Conference Room:<span style={{ fontWeight: 'normal' }}>{alias}</span></h3>
        <h3>PIN:<span style={{ fontWeight: 'normal' }}>{hostPin}#</span></h3>
        <h3><CopyTextButton {...CopyTextButtonProps} /></h3>
      </div>
    </div>
  );
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.shape({
    alias: PropTypes.string,
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    hostLink: PropTypes.string,
    hostPin: PropTypes.string,
  })
};
