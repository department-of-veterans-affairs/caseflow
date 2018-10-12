import React, { Fragment } from 'react';
import Alert from '../../components/Alert';
import { css } from 'glamor';
import { COLORS } from '../../constants/AppConstants';
import classnames from 'classnames';
import PropTypes from 'prop-types';

const headerStyling = css({
  marginBottom: '34px',
  fontSize: '42px',
  paddingLeft:'5rem',
  paddingTop: '9rem'
});

const bodyStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  display: 'block'
});

const messageStyling = css({
  paddingLeft: '9.8rem',
  fontSize: '3rem',
  paddingRight: '9rem',
  paddingBottom: '9.8rem'
})

export default class AssignStatusMessage extends React.PureComponent {

  render() {
      let {
        children,
        message,
        title,
        styling
      } = this.props;

      return <div>
        <div className="usa-alert-body" {...bodyStyling}{...styling}>
          <h2 className="usa-alert-heading cf-red-text" {...headerStyling}>{title}</h2>
          { children ? <div className="usa-alert-text">{children}</div> :
            <div className="usa-alert-text" {...messageStyling}>{message}</div>}
        </div>
      </div>;
    }
  }

  AssignStatusMessage.propTypes = {
    children: PropTypes.node,
    message: PropTypes.node,
    title: PropTypes.string,
    styling: PropTypes.string
  };
