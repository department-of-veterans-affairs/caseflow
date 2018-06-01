import { after, css, merge } from 'glamor';
import React from 'react';

import { COLORS } from '../constants/AppConstants';

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
    <h1 {...headerStyling}>{this.props.heading}</h1>
    <ul className="usa-unstyled-list usa-nav-secondary-links" {...listStyling}>
      {this.props.children.map((child, i) => <li key={i}>{child}</li>)}
    </ul>
    <hr {...horizontalRuleStyling} />
  </React.Fragment>;
}
