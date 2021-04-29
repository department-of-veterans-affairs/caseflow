import { css } from 'glamor';

export const pageHeader = css({
  borderBottom: '1px solid #D6D7D9',
  marginBottom: '3.6rem',
  paddingBottom: '1.9rem',
  '& > h1': {
    marginBottom: '2.4rem',
  },
});

export const sectionStyle = css({
  marginBottom: '24px',
  '& h2': {
    marginBottom: '.8rem',
  },
});
