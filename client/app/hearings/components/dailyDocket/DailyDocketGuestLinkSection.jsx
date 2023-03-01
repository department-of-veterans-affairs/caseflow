import React from 'react';
import PropTypes from 'prop-types';
import CopyTextButton from '../../../components/CopyTextButton';

export const DailyDocketGuestLinkSection = ({ linkInfo, hasAccess }) => {

  const { alias, guestLink, guestPin } = linkInfo;

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

  const CopyTextButtonProps = {
    text: 'Copy Guest Link',
    label: 'Copy Guest Link',
    textToCopy: guestLink
  };

  return (
    <div style={containerStyle}>
      <h3>Guest links for non-virtual hearings</h3>
      <div style={roomInfoContainerStyle}>
        <h3>Conference Room:<span style={{ fontWeight: 'normal' }}>{alias}</span></h3>
        <h3>PIN:<span style={{ fontWeight: 'normal' }}>{guestPin}#</span></h3>
        {hasAccess && <h3><CopyTextButton {...CopyTextButtonProps} /></h3>}

      </div>
    </div>
  );
};

DailyDocketGuestLinkSection.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
  hasAccess: PropTypes.bool
};
