import { css } from 'glamor';

export const rowStyles = css({
  display: 'flex',
  justifyContent: 'space-between'
});

export const viewedParagraphStyles = css({
  marginTop: '15px'
});

export const issueStyles = css({
  marginTop: '20px',
  '& ol': {
    paddingTop: '3px',
    paddingLeft: '1em',
    marginTop: 0,
    marginBottom: 0
  }
});
