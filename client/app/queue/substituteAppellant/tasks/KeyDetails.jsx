import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { format, isDate, parseISO } from 'date-fns';
import { css } from 'glamor';

const styles = {
  detailList: css({
    listStyle: 'none',
    margin: 0,
    padding: 0,
    '& > li': {
      '& > strong': {
        ':after': {
          content: ': ',
        },
      },
    },
  }),
};

export const KeyDetails = (props) => {
  const { nodDate, dateOfDeath, substitutionDate } = useMemo(() => {
    const formatted = {};

    ['nodDate', 'dateOfDeath', 'substitutionDate'].forEach((key) => {
      formatted[key] = format(
        isDate(props[key]) ? props[key] : parseISO(props[key]),
        'M/d/y'
      );
    });

    return formatted;
  }, [props]);

  return (
    <section>
      <h2>Key details</h2>
      <ul className={styles.detailList}>
        <li>
          <strong>Notice of disagreement received</strong>
          <span>{nodDate}</span>
        </li>
        <li>
          <strong>Veteran date of death</strong>
          <span>{dateOfDeath}</span>
        </li>
        <li>
          <strong>Substitution granted by the RO</strong>
          <span>{substitutionDate}</span>
        </li>
      </ul>
    </section>
  );
};
KeyDetails.propTypes = {
  nodDate: PropTypes.oneOfType([PropTypes.instanceOf(Date), PropTypes.string]),
  dateOfDeath: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
  substitutionDate: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
};
