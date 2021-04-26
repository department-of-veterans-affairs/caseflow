import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { format, isDate, parseISO } from 'date-fns';
import { css } from 'glamor';

const styles = {
  mainTable: css({
    '& > tbody > tr > td': {
      verticalAlign: 'top',
      ':first-child': {
        fontWeight: 'bold',
      },
    },
    '& table': {
      margin: 0,
      '& tr:first-of-type td': {
        borderTop: 'none',
      },
      '& tr:last-of-type td': {
        borderBottom: 'none',
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
      <table className={`usa-table-borderless ${styles.mainTable}`}>
        <tbody>
          <tr>
            <td>NOD received</td>
            <td>{nodDate}</td>
          </tr>
          <tr>
            <td>Veteran date of death</td>
            <td>{dateOfDeath}</td>
          </tr>
          <tr>
            <td>Substitution granted by the RO</td>
            <td>{substitutionDate}</td>
          </tr>
        </tbody>
      </table>
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
