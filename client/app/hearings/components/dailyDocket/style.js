import { css } from 'glamor';

export const docketRowStyle = css({
  borderBottom: '1px solid #ddd',
  '& > div': {
    display: 'inline-block',
    '& > div': {
      verticalAlign: 'top',
      display: 'inline-block',
      padding: '15px'
    }
  },
  '& > div:nth-child(1)': {
    width: '40%',
    '& > div:nth-child(1)': { width: '15%' },
    '& > div:nth-child(2)': { width: '5%' },
    '& > div:nth-child(3)': { width: '50%' },
    '& > div:nth-child(4)': { width: '25%' }
  },
  '& > div:nth-child(2)': {
    backgroundColor: '#f1f1f1',
    width: '60%',
    '& > div': { width: '50%' }
  },
  '&:not(.judge-view) > div:nth-child(1) > div:nth-child(1)': {
    display: 'none'
  },
  '&.hide': {
    display: 'none'
  }
});

export const inputSpacing = css({
  '&>div:not(:first-child)': {
    marginTop: '25px'
  }
});
