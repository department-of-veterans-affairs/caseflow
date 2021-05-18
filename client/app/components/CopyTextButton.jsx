import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import CopyToClipboard from 'react-copy-to-clipboard';
import Tooltip from '../components/Tooltip';
import { COLORS } from '../constants/AppConstants';
import { ClipboardIcon } from '../components/RenderFunctions';
import { isEmpty } from 'lodash';

export const clipboardButtonStyling = (defaults) =>
  css({
    ...defaults,
    padding: '0.75rem',
    // Offset the additional padding so when this component appears in an unordered list of items its baseline matches.
    margin: '-0.75rem 0',
    overflowWrap: 'break-word'
  });

export default class CopyTextButton extends React.PureComponent {
  render = () => {
    const { text, textToCopy, label, styling } = this.props;
    const buttonStyles = isEmpty(styling) ?
      {
        borderColor: COLORS.GREY_LIGHT,
        borderWidth: '1px',
        color: COLORS.GREY_DARK,
        ':hover': {
          backgroundColor: 'transparent',
          color: COLORS.GREY_DARK,
          borderColor: COLORS.PRIMARY,
          borderBottomWidth: '1px'
        },
        '& > svg path': { fill: COLORS.GREY_LIGHT },
        '&:hover > svg path': { fill: COLORS.PRIMARY }
      } :
      styling;

    return (
      <Tooltip id={`tooltip-${text}`} text="Click to copy" position="bottom">
        <CopyToClipboard text={textToCopy || text}>
          <button
            type="submit"
            className="cf-apppeal-id"
            aria-label={`Click to copy ${label} ${text}`}
            {...clipboardButtonStyling(buttonStyles)}
          >
            {text}&nbsp;
            <ClipboardIcon />
          </button>
        </CopyToClipboard>
      </Tooltip>
    );
  };
}

CopyTextButton.defaultProps = {
  styling: {},
  label: '',
  textToCopy: null
};

CopyTextButton.propTypes = {
  text: PropTypes.string.isRequired,

  /**
   * If set, this text will be copied instead of the contents of the `text` prop
   */
  textToCopy: PropTypes.string,

  /**
   * Populates into the aria-label as `Copy ${label} ${text}`
   */
  label: PropTypes.string,
  styling: PropTypes.object
};
