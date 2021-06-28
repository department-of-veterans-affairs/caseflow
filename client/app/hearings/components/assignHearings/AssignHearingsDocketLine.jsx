import { css } from 'glamor';
import _ from 'lodash';

export const docketCutoffLineStyle = (_index, scheduledForText) => {
  const isEmpty = _index < 0;
  const index = isEmpty ? 0 : _index;
  const style = {
    [`& #table-row-${index + 1} td`]: {
      paddingTop: '35px'
    },
    [`& #table-row-${index}`]: {
      borderBottom: '2px solid #000',
      position: 'relative',
      '& td': {
        paddingBottom: '35px'
      },
      '& td:first-child::before': {
        content: `Schedule for ${scheduledForText}`,
        display: 'block',
        position: 'absolute',
        transform: 'translateY(calc(155% + 4px))',
        background: '#fff',
        padding: '10px 10px 10px 0px',
        height: '42px',
        fontWeight: 'bold'
      }
    }
  };

  const isEmptyStyle = isEmpty ? {
    '& th': {
      paddingBottom: '35px'
    },
    [`& #table-row-${index}`]: {
      borderTop: '2px solid #000',
      borderBottom: 0,
      '& td': {
        paddingTop: '35px',
        paddingBottom: '15px'
      },
      '& td:first-child::before': {
        transform: 'translateY(-215%)',
        content: `All veterans have been scheduled through ${scheduledForText}`
      },
      '@media screen and (min-width: 1224px) and (max-width: 1680px)': {
        '& td:first-child::before': {
          height: 'auto',
          paddingBottom: '20px',
        },
      }
    }
  } : {};

  return css(_.merge(style, isEmptyStyle));
};
