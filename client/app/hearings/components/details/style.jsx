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

export const rowThirds = css({
  marginTop: '30px',
  marginBottom: '30px',
  marginLeft: '-15px',
  marginRight: '-15px',
  '& > *': {
    display: 'inline-block',
    paddingLeft: '15',
    paddingRight: '15px',
    verticalAlign: 'top',
    margin: 0,
    width: '33.333333333333%'
  }
});

export const fullWidth = css({
  display: 'block',
  maxWidth: '100%'
});
