import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import AppealDocumentCount from './AppealDocumentCount';
import { CATEGORIES } from './constants';
import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';

const containingDivStyling = css({
  borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
  display: 'block',
  // Offsets the padding from .cf-app-segment--alt to make the bottom border full width.
  margin: '-2rem -4rem 0 -4rem',
  padding: '0 0 1.5rem 4rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const headerStyling = css({
  paddingRight: '2.5rem'
});

const listStyling = css({
  listStyleType: 'none',
  verticalAlign: 'super',
  padding: '0'
});

const listItemStyling = css({
  display: 'inline',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }
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
  render = () => <div {...containingDivStyling}>
    <h1 {...headerStyling}>{this.props.heading}</h1>
    <ul {...listStyling}>
      {this.props.children.map((child, i) => <li key={i} {...listItemStyling}>{child}</li>)}
    </ul>
  </div>;
}
