import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { format, isDate, parseISO } from 'date-fns';
import { css } from 'glamor';
import { Link } from 'react-router-dom';
import { CAVC_REMAND_MODIFY_TASKS_KEY_DETAILS } from 'app/../COPY';

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
  caseDetails: css({
    marginTop: '1rem',
    '& > a': {
      fontWeight: 'bold',
      '& > i': {
        verticalAlign: 'middle'
      }
    }
  })
};

export const KeyDetails = (props) => {
  const { nodDate, dateOfDeath, substitutionDate } = useMemo(() => {
    const formatted = {};

    ['nodDate', 'dateOfDeath', 'substitutionDate'].forEach((key) => {
      formatted[key] = props[key] !== null ? format(
        isDate(props[key]) ? props[key] : parseISO(props[key]),
        'M/d/y'
      ) : 'Value not set';
    });

    return formatted;
  }, [props]);

  return (
    <section className={props.className}>
      <h2>{CAVC_REMAND_MODIFY_TASKS_KEY_DETAILS}</h2>
      <ul className={styles.detailList}>
        <li>
          <strong>Notice of disagreement received</strong>
          <span>{nodDate}</span>
        </li>

        { props.dateOfDeath !== null && props.isAppellantSubstituted === 'true' && (
          <>
            <li>
              <strong>Veteran date of death</strong>
              <span>{dateOfDeath}</span>
            </li>
          </>
        )}

        { props.isAppellantSubstituted === 'true' && (
          <>
            <li>
              <strong>Substitution granted by the RO</strong>
              <span>{substitutionDate}</span>
            </li>
          </>
        )}
      </ul>
      <div className={styles.caseDetails}>
        <Link to={`/queue/appeals/${props.appealId}`} target="_blank">
          View existing case details <i className="fa fa-external-link"></i>
        </Link>
      </div>
    </section>
  );
};
KeyDetails.propTypes = {
  appealId: PropTypes.string.isRequired,
  className: PropTypes.oneOfType([PropTypes.string, PropTypes.object]),
  nodDate: PropTypes.oneOfType([PropTypes.instanceOf(Date), PropTypes.string]),
  dateOfDeath: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
  substitutionDate: PropTypes.oneOfType([
    PropTypes.instanceOf(Date),
    PropTypes.string,
  ]),
  isAppellantSubstituted: PropTypes.string
};
