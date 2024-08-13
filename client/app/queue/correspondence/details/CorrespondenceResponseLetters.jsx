import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';

const CorrespondenceResponseLetters = (props) => {
  const { letters } = props;

  return (
    <div className="correspondence-package-details">
      <h2 className="correspondence-h2"><strong>Response Letters</strong></h2>
      {letters.map((letter, index) => (
        <div key={index}>
          <table className="response-letter-table-borderless-no-background gray-border">
            <tbody>
              <tr>
                <td className="response-letter-table-borderless-first-item">
                  <strong>Letter response expiration:</strong>
                  <span className="response-letter-table-borderless">
                    {letter.days_left}
                  </span>
                </td>
              </tr>
              <tr>
                <th className="response-letter-table-borderless-second-item"><strong>Date response letter sent</strong></th>
                <th className="response-letter-table-borderless-second-item"><strong>Letter type</strong></th>
                <th className="response-letter-table-borderless-second-item"><strong>Letter title</strong></th>
                <th className="response-letter-table-borderless-second-item"><strong>Letter subcategory</strong></th>
              </tr>
              <tr>
                <td colSpan="4" className="hr-container">
                  <hr className="full-width-hr" />
                </td>
              </tr>
              <tr>
                <td className="response-letter-table-borderless-last-item">{moment(letter.date_sent).format('MM/DD/YYYY')}</td>
                <td className="response-letter-table-borderless-last-item">{letter.letter_type}</td>
                <td className="response-letter-table-borderless-last-item">{letter.title}</td>
                <td className="response-letter-table-borderless-last-item">{letter.subcategory.split( )}</td>
              </tr>
              &nbsp;
            </tbody>
          </table>
        </div>
      ))}
    </div>
  );
};

CorrespondenceResponseLetters.propTypes = {
  letters: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      correspondence_id: PropTypes.number,
      letter_type: PropTypes.string,
      title: PropTypes.string,
      subcategory: PropTypes.string,
      reason: PropTypes.string,
      date_sent: PropTypes.string,
      response_window: PropTypes.number,
      user_id: PropTypes.number,
      days_left: PropTypes.string, // This will contain either the days left or 'No response window required'
      expired: PropTypes.oneOfType([
        PropTypes.string, // Expired date as string
        PropTypes.bool    // false when not expired
      ]),
    })
  ).isRequired
};

export default CorrespondenceResponseLetters;
