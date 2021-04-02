import { css } from 'glamor';
import { COLORS } from '../../../constants/AppConstants';

export const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  }
});

// Used by HearingDayInfoButton
const buttonCommonStyle = {
  width: '90%',
  paddingTop: '1.5rem',
  paddingBottom: '1.5rem',
  outline: 'none'
};

export const buttonUnselectedStyle = css(
  buttonCommonStyle
);

export const buttonSelectedStyle = css(
  {
    ...buttonCommonStyle,
    ...{
      backgroundColor: COLORS.BLUE_DARKEST,
      color: COLORS.WHITE,
      borderRadius: '0.1rem 0.1rem 0 0',
      '&:hover': {
        backgroundColor: COLORS.BLUE_DARKEST,
        color: COLORS.WHITE
      }
    }
  });

export const dateStyle = css({ fontWeight: 'bold' });

export const leftColumnStyle = css({
  width: '60%',
  display: 'inline-block',
  textAlign: 'left'
});
export const rightColumnStyle = css({
  width: '40%',
  display: 'inline-block',
  textAlign: 'right',
  overflowX: 'hidden',
  overflowY: 'hidden'
});
export const typeAndJudgeStyle = css({
  textOverflow: 'ellipsis',
  overflowX: 'hidden',
  overflowY: 'hidden',
  whiteSpace: 'nowrap'
});
