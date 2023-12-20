import React from 'react';
import PropTypes from 'prop-types';
import { Link as RouterLink } from 'react-router-dom';
import { css } from 'glamor';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

const CLASS_NAME_MAPPING = {
  primary: 'usa-button',
  secondary: 'usa-button-secondary',
  disabled: 'usa-button-disabled',
  matte: 'link-matte link-overflow'
};

const disabledLinkStyling = css({
  color: COLORS.GREY_MEDIUM,
  ':hover': {
    color: COLORS.GREY_MEDIUM
  }
});

const matteStyling = css({
  margin: '0 8px',
  color: 'inherit',
  padding: '0',
  backgroundColor: 'transparent',
  fontSize: 'inherit',
  pointerEvents: 'all',
  lineHeight: 'normal',

  ':visited': {
    color: 'inherit'
  },

  ':hover': {
    textDecoration: 'none',
    backgroundColor: 'transparent',
    color: COLORS.PRIMARY_ALT,

    '& svg g': {
      fill: COLORS.PRIMARY_ALT
    }
  },

  '& svg': {
    verticalAlign: 'bottom'
  },

  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
  overflowX: 'hidden',
  maxWidth: '100%'
});

export default class Link extends React.Component {
  render() {
    const {
      ariaLabel,
      to,
      target,
      name,
      onClick,
      onMouseUp,
      href,
      button,
      children,
      replace,
      disabled
    } = this.props;

    if (disabled) {
      return <span {...disabledLinkStyling}>
        {children}
      </span>;
    }

    const type = button ? 'button' : null;
    const styling = button === 'matte' ? matteStyling : {};

    if (button === 'disabled') {
      return <p
        type={type}
        className={CLASS_NAME_MAPPING[button]}
        {...styling}
      >
        {children}
      </p>;
    }

    const commonProps = {
      ...styling,
      'aria-label': ariaLabel,
      target,
      type,
      id: name,
      className: CLASS_NAME_MAPPING[button],
      onClick,
      onMouseUp
    };

    if (to) {
      return <RouterLink to={to} replace={replace} {...commonProps}>
        {children}
      </RouterLink>;
    }

    return <a href={href} {...commonProps}>
      {children}
    </a>;

  }
}

Link.propTypes = {
  href: PropTypes.string,
  name: PropTypes.string,
  target: PropTypes.string,
  ariaLabel: PropTypes.string,
  to: PropTypes.string,
  button: PropTypes.string,
  onMouseUp: PropTypes.func,
  onClick: PropTypes.func,
  children: PropTypes.node,
  replace: PropTypes.bool,
  disabled: PropTypes.bool
};
