import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import CopyToClipboard from 'react-copy-to-clipboard';
import Tooltip from '../components/Tooltip';
import { COLORS } from '../constants/AppConstants';
import { ClipboardIcon } from '../components/RenderFunctions';

const clipboardButtonStyling = css({
  borderColor: COLORS.GREY_LIGHT,
  borderWidth: '1px',
  color: COLORS.GREY_DARK,
  padding: '0.75rem',
  // Offset the additional padding so when this component appears in an unordered list of items its baseline matches.
  margin: '-0.75rem 0',
  ':hover': {
    backgroundColor: 'transparent',
    color: COLORS.GREY_DARK,
    borderColor: COLORS.PRIMARY,
    borderBottomWidth: '1px'
  },
  overflowWrap: 'break-word',
  '& > svg path': { fill: COLORS.GREY_LIGHT },
  '&:hover > svg path': { fill: COLORS.PRIMARY }
});

export default class CopyTextButton extends React.PureComponent {
  render = () => {
    const { text, textToCopy, label } = this.props;

    return (
      <Tooltip id={`tooltip-${text}`} text="Click to copy" position="bottom">
        <CopyToClipboard text={textToCopy || text}>
          <button
            type="submit"
            className="cf-apppeal-id"
            aria-label={`Copy ${label} ${text}`}
            {...clipboardButtonStyling}
          >
            {text}&nbsp;
            <ClipboardIcon />
          </button>
        </CopyToClipboard>
      </Tooltip>
    );
  };
}

CopyTextButton.propTypes = {
  text: PropTypes.string.isRequired,
  textToCopy: PropTypes.string,
  label: PropTypes.string
};
