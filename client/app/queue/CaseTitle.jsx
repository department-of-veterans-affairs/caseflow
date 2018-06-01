import { after, css, merge } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import AppealDocumentCount from './AppealDocumentCount';
import { CATEGORIES } from './constants';
import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';

const headerStyling = css({
  float: 'left',
  margin: 0,
  marginTop: '-2rem'
});
const listStyling = css({
  marginTop: '-1.5rem',
  marginLeft: '1rem',
  '& li': {
    float: 'left',
    paddingTop: '0.5rem',
    paddingBottom: '0.5rem'
  },
  // Replaces pipe character with right border
  '& li:not(:last-child)': merge(
    after({ content: '""' }),
    { borderRight: `1px solid ${COLORS.GREY_LIGHT}` }
  )
});

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  clear: 'both',
  // Offsets the padding from .cf-app-segment--alt to make the hr full width.
  margin: '0 -4rem',
  marginTop: '4rem'
});

export default class CaseTitle extends React.PureComponent {
  render = () => <React.Fragment>
    <h1 {...headerStyling}>{this.props.appeal.attributes.veteran_full_name}</h1>
    <ul className="usa-unstyled-list usa-nav-secondary-links" {...listStyling}>
      <li>Veteran ID: <b>{this.props.appeal.attributes.vbms_id}</b></li>
      <li>
        <ReaderLink
          vacolsId={this.props.vacolsId}
          analyticsSource={CATEGORIES.QUEUE_TASK}
          redirectUrl={window.location.pathname}
          appeal={this.props.appeal}
          taskType="Draft Decision"
          message={
            <React.Fragment>View <AppealDocumentCount appeal={this.props.appeal} /> documents</React.Fragment>
          } />
      </li>
    </ul>
    <hr {...horizontalRuleStyling} />
  </React.Fragment>;
}

CaseTitle.propTypes = {
  appeal: PropTypes.object,
  vacolsId: PropTypes.string.isRequired
};
