import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { COLORS } from '../constants/AppConstants';
import { ExternalLinkIcon } from 'app/components/icons/ExternalLinkIcon';

const EfolderLink = ({ url, veteranParticipantId }) => {

  return (
    <a href={url} target="_blank" rel="noopener noreferrer">
      {veteranParticipantId ? 'Open eFolder ' : 'Go to eFolder Search '}
      <span {...css({ position: 'relative', top: '3px' })}>
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
