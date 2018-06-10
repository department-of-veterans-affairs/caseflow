import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import AppealDocumentCount from './AppealDocumentCount';
import { CATEGORIES } from './constants';
import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';

const headerStyling = css({
  float: 'left',
  listStyleType: 'none',
  margin: 0,
  marginTop: '-2rem'
});

const listStyling = css({
  float: 'left',
  listStyleType: 'none',
  margin: '-1.5rem 0 0 1rem',
  padding: 0
});

const listItemStyling = css({
  float: 'left',
  padding: '0.5rem 1.5rem',
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` }
});

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  clear: 'both',
  // Offsets the padding from .cf-app-segment--alt to make the hr full width.
  margin: '4rem -4rem 0 -4rem'
});

export default class CaseTitle extends React.PureComponent {
  render = () => {
    const { appeal, vacolsId, redirectUrl } = this.props;

    return <CaseTitleScaffolding heading={appeal.attributes.veteran_full_name}>
      <React.Fragment>Veteran ID: <b>{appeal.attributes.vbms_id}</b></React.Fragment>
      <ReaderLink
        vacolsId={vacolsId}
        analyticsSource={CATEGORIES.QUEUE_TASK}
        redirectUrl={redirectUrl}
        appeal={appeal}
        taskType="Draft Decision"
        message={<React.Fragment>View <AppealDocumentCount appeal={appeal} /> documents</React.Fragment>} />
    </CaseTitleScaffolding>;
  }
}

CaseTitle.propTypes = {
  appeal: PropTypes.object.isRequired,
  redirectUrl: PropTypes.string.isRequired,
  vacolsId: PropTypes.string.isRequired
};

class CaseTitleScaffolding extends React.PureComponent {
  render = () => <React.Fragment>
    <h1 {...headerStyling}>{this.props.heading}</h1>
    <ul {...listStyling}>
      {this.props.children.map((child, i) => <li key={i} {...listItemStyling}>{child}</li>)}
    </ul>
    <hr {...horizontalRuleStyling} />
  </React.Fragment>;
}
