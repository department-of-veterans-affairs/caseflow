import { css } from 'glamor';
import { COLORS } from '../../../constants/AppConstants';

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

export const rowThirds = css({
  marginTop: 30,
  marginBottom: 30,
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
});
