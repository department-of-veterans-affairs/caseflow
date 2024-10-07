import React from 'react';
import PropTypes from 'prop-types';
import { COLORS } from '../constants/AppConstants';
import { ExternalLinkIcon } from 'app/components/icons/ExternalLinkIcon';

const EfolderLink = ({ url, veteranParticipantId }) => {
  const spanStyle = {
    position: 'relative',
    top: '3px'
  };

  return (
    <a href={url} target="_blank" rel="noopener noreferrer">
      {veteranParticipantId ? 'Open eFolder ' : 'Go to eFolder Search '}
      <span style={spanStyle}>
        <ExternalLinkIcon color={COLORS.FOCUS_OUTLINE} />
      </span>
    </a>
  );
};

EfolderLink.propTypes = {
  url: PropTypes.string,
  veteranParticipantId: PropTypes.string
};

export default EfolderLink;
