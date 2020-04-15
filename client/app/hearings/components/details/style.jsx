import { css } from 'glamor';
import { COLORS } from '../../../constants/AppConstants';

export const maxWidthFormInput = css({
  display: 'block',
  maxWidth: '100%'
});

export const listStyling = css({
  verticalAlign: 'super',
  '::after': {
    content: ' ',
    clear: 'both',
    display: 'block'
  }
});

export const listItemStyling = css({
  display: 'block',
  float: 'left',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':not(:last-child)': {
    '& > div': {
      borderRight: `1px solid ${COLORS.GREY_LIGHT}`
    },
    '& > *': {
      paddingRight: '1.5rem',
      minHeight: '22px'
    }
  },
  '& > h4': { textTransform: 'uppercase' }
});

export const flexParent = css({
  display: 'flex'
});

// Column for flexParent that takes one third of the space.
export const columnThird = css({
  paddingLeft: 0,
  paddingRight: 15,
  flex: 1,
  margin: 0
});

// Spacer column that occupies 2/3 of flexParent.
export const columnDoubleSpacer = css({
  flex: '2 1 auto',
  paddingLeft: 45
});

// Generic row element for consistent spacing.
export const genericRow = css({
  marginTop: 30,
  marginBottom: 30
});

// Container element for a row with 3 columns.
export const rowThirds = css(
  genericRow,
  {
    display: 'flex',
    '& > *': {
      paddingLeft: 15,
      paddingRight: 15,
      flex: 1,
      margin: 0
    },
    '& > :first-child': {
      paddingLeft: 0
    },
    '& > :last-child': {
      paddingRight: 0
    }
  }
);

// Container element for a row with 3 columns, where the last
// column is a spacer.
//
// For small screen sizes, the spacer column collpases, and the first 2 columns
// fill the entire space.
export const rowThirdsWithFinalSpacer = css(
  rowThirds,
  {
    '@media screen and (max-width: 1302px)': {
      '& > :nth-child(2)': {
        paddingLeft: 15,
        paddingRight: 0
      },
      '& > :last-child': {
        flex: '0 !important',
        paddingLeft: 0,
        paddingRight: 0
      }
    }
  }
);
