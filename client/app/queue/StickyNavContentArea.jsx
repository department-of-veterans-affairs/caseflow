import { css } from 'glamor';
import React from 'react';

import StringUtil from '../util/StringUtil';
import { COLORS } from '../constants/AppConstants';

const sectionNavigationContainerStyling = css({
  float: 'left',
  paddingRight: '3rem',
  position: 'sticky',
  top: '3rem',
  width: '20%',
  '@media (max-width: 1020px)': {
    backgroundColor: COLORS.WHITE,
    paddingTop: '1rem',
    top: 0,
    paddingRight: 0,
    width: '100%'
  }
});

const sectionNavigationListStyling = css({
  '& > li': {
    backgroundColor: COLORS.GREY_BACKGROUND,
    color: COLORS.PRIMARY,
    borderWidth: 0
  },
  '& > li:hover': {
    backgroundColor: COLORS.GREY_DARK,
    color: COLORS.WHITE
  },
  '& > li > a': { color: COLORS.PRIMARY },
  '& > li:hover > a': {
    background: 'none',
    color: COLORS.WHITE
  },
  '& > li > a:after': {
    content: '〉',
    float: 'right'
  },
  '@media (max-width: 1020px)': {
    display: 'flex',
    flexFlow: 'row',
    borderBottom: 'none',
    borderTop: 'none',
    width: '100%',
    marginBottom: '1rem',
    '& > li': {
      padding: '0.75rem 0.75rem',
      fontSize: '1.5rem',
      flexGrow: 1,
      '&:first-child': {
        borderRadius: '5px 0 0 5px'
      },
      '&:last-child': {
        borderRadius: '0 5px 5px 0'
      },
      '& > a': {
        padding: 0
      },
      '& > a:after': {
        content: 'none'
      }
    }
  }
});

const sectionBodyStyling = css({
  float: 'left',
  width: '80%',
  '@media (max-width: 1020px)': {
    flex: '1 100%',
    width: '100%'
  }
});

const getIdForElement = (elem) => `${StringUtil.parameterize(elem.props.title)}-section`;

export default class StickyNavContentArea extends React.PureComponent {
  render = () => {
    // Ignore undefined child elements.
    const childElements = this.props.children.filter((child) => typeof child === 'object');

    return <React.Fragment>
      <aside {...sectionNavigationContainerStyling}>
        <ul className="usa-sidenav-list" {...sectionNavigationListStyling}>
          {childElements.map((child, i) =>
            <li key={i}><a href={`#${getIdForElement(child)}`}>{child.props.title}</a></li>)}
        </ul>
      </aside>

      <div {...sectionBodyStyling}>
        {childElements.map((child, i) => <ContentSection key={i} element={child} />)}
      </div>
    </React.Fragment>;
  };
}

export const sectionSegmentStyling = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderTop: '0px',
  marginBottom: '3rem',
  padding: '1rem 2rem'
});

export const sectionHeadingStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderBottom: 0,
  borderRadius: '0.5rem 0.5rem 0 0',
  margin: 0,
  padding: '1rem 2rem'
});

export const anchorJumpLinkStyling = css({
  color: COLORS.GREY_DARK,
  paddingTop: '7rem',
  textDecoration: 'none',
  pointerEvents: 'none',
  cursor: 'default'
});

const ContentSection = ({ element }) => <React.Fragment>
  <h2 {...sectionHeadingStyling}>
    <a id={`${getIdForElement(element)}`} {...anchorJumpLinkStyling}>{element.props.title}</a>
    {element.props.additionalHeaderContent && element.props.additionalHeaderContent}
  </h2>
  <div {...sectionSegmentStyling}>{element}</div>
</React.Fragment>;

