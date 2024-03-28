import { css } from 'glamor';

export const labelPaddingFirst = css({
  paddingBottom: 5,
  paddingTop: 5
});

export const labelPadding = css({
  paddingBottom: 15
});

export const maxWidthFormInput = css({
  display: 'block',
  maxWidth: '100%'
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

// Generic row element for consistent spacing.
export const genericRow = css({
  marginTop: 30,
  marginBottom: 30
});

// Container element for a row with 3 columns.
export const rowThirds = css(genericRow, {
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

export const enablePadding = css({
  paddingLeft: '15px !important'
});

export const hearingLinksContainer = css({
  marginBottom: 38
});

export const fullWidth = css({ display: 'flex', flex: 1 });

export const leftAlign = css({
  marginTop: 30,
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
  },
});

export const marginTop = (margin) =>
  css({
    marginTop: margin
  });

export const timezoneDropdownStyles = (count) => ({
  height: `${count * 39}px !important`,
  maxHeight: 'none'
});

export const timezoneStyles = (count) => ({
  '& .cf-select__menu-list': {
    height: `${count * 39}px !important`,
    maxHeight: 'none',
    overflowY: 'auto',
    [`& > :nth-child(${count})`]: {
      borderBottom: '1px solid grey'
    }
  }
});

export const verticalAlign = css({
  flexDirection: 'column',
  display: 'flex',
  '& > :first-child': {
    flex: 1,
    '& .cf-form-radio-options': {
      flexDirection: 'column',
      display: 'flex',
    },
  },
  '& > :last-child': {
    flex: 1,
    paddingLeft: 0
  },
});

export const inputFix = css({
  '& .question-label': {
    marginBottom: '2rem !important',
  },
});

export const input8px = css({
  '& .question-label': {
    marginBottom: '8px !important',
  },
});

export const emailConfirmationModalStyles = css({
  '& pre': {
    margin: '5px 0'
  }
});

export const regionalOfficeSection = css({
  lineHeight: '200%',
  '& .cf-form-radio-option': {
    lineHeight: '100%'
  },
  '& .usa-input-error-message': {
    margin: '10px 0',
  },
  '& .usa-input-error': {
    lineHeight: '100%',
    margin: 0,
    paddingLeft: 15
  },
  '& pre': {
    margin: 0,
    lineHeight: '125%'
  }
});

export const spacing = (space, el) => css({
  [`& ${el}`]: {
    margin: space
  }
});

export const cancelButton = css({ float: 'left', paddingLeft: 0, paddingRight: 0 });

export const saveButton = css({ float: 'right' });

export const setMargin = (margin) =>
  css({
    margin
  });

export const notesFieldStyling = css({
  height: '100px',
  fontSize: '10pt'
});

export const roomRequiredStyling = css({
  marginTop: '15px'
});

export const statusMsgTitleStyle = css({
  fontSize: '18pt',
  textAlign: 'left'
});
export const statusMsgDetailStyle = css({
  fontSize: '12pt',
  textAlign: 'left',
  margin: 0,
  color: '#e31c3d'
});

export const titleStyling = css({
  marginBottom: 0,
  padding: 0
});
