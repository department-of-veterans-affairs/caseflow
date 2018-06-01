import { css } from 'glamor';
import React from 'react';

import { COLORS } from '../constants/AppConstants';

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
  render = () => <React.Fragment>
    <h1 {...headerStyling}>{this.props.heading}</h1>
    <ul {...listStyling}>
      {this.props.children.map((child, i) => <li key={i} {...listItemStyling}>{child}</li>)}
    </ul>
    <hr {...horizontalRuleStyling} />
  </React.Fragment>;
}
