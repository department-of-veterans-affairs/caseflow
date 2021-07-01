import { css } from 'glamor';
import { COLORS } from '../../../constants/AppConstants';

export const tableNumberStyling = css({
  '& tr > td:first-child': {
    paddingRight: 0
  }
});

// Used by AssignHearings, contains multiple HearingDayInfoButton(s)
const hearingDayButtonWidth = 276;

export const hearingDayListHorizontalRuleStyle = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: 0,
  marginBottom: 0,
  marginRight: `calc(100% - ${hearingDayButtonWidth}px)`
});

export const sectionNavigationListStyling = css({
  '& > li': {
    color: COLORS.PRIMARY,
    borderWidth: 0
  }
});

export const roSelectionStyling = css({ marginTop: '10px', minWidth: 310 });

// Used by HearingDayInfoButton
const buttonCommonStyle = {
  width: hearingDayButtonWidth,
  paddingTop: '1.5rem',
  paddingBottom: '1.5rem',
};

export const buttonUnselectedStyle = css(
  buttonCommonStyle
);

export const buttonSelectedStyle = css(
  {
    ...buttonCommonStyle,
    ...{
      fontWeight: 700,
      backgroundColor: COLORS.BLUE_DARKEST,
      color: COLORS.WHITE,
      borderRadius: '0.1rem 0.1rem 0 0',
      '&:hover': {
        backgroundColor: COLORS.BLUE_DARKEST,
        color: COLORS.WHITE
      }
    }
  });

const bottomPadInsideColumn = { paddingBottom: '0.5rem' };

export const slotDisplayStyle = css({
  ...bottomPadInsideColumn,
});

export const dateStyle = css({
  ...bottomPadInsideColumn,
  ...{ fontWeight: 'bold' }
});

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
  fontSize: 15,
  textOverflow: 'ellipsis',
  overflowX: 'hidden',
  overflowY: 'hidden',
  whiteSpace: 'nowrap'
});

export const scheduledDisplayStyle = css({
  fontSize: 15,
});
