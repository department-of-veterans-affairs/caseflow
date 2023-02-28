import React, { useState } from 'react';
import { COLORS } from '../../../constants/AppConstants';
import PropTypes from 'prop-types';
import { right } from 'glamor';

export const DailyDocketGuestLinkSection = () => {
  const [linkInfo, setLinkInfo] = useState({});

  const containerStyle = {
    display: 'grid',
    gridTemplateColumns: '1fr 3fr',
    backgroundColor: '#f1f1f1',
    padding: '0.7em 0 0 1em',
  };

  const roomInfoContainerStyle = {
    display: 'flex',
    justifyContent: 'space-around'
  };

  return (
    <div style={containerStyle}>
      <h3>Guest links for</h3>
      <div style={roomInfoContainerStyle}>
        <h3>Conference Room:</h3>
        <h3>PIN:</h3>
        <h3>Guest Link</h3>
      </div>
    </div>
  );
};
