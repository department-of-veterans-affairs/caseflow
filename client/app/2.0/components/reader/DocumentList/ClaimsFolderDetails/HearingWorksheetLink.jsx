import React from 'react';
import PropTypes from 'prop-types';

/**
 * Hearing Worksheet Link React Component
 * @param {Object} props -- React props containing the hearings
 */
export const HearingWorksheetLink = ({ hearings }) => {
  return (
    <span>
      {hearings.map((hearing, key) => {
        return (
          <div>
            <a target="_blank"
              href={`/hearings/worksheet/print?keep_open=true&hearing_ids=${hearing.external_id}`}
              rel="noopener noreferrer"
              key={key}>Hearing Worksheet</a>
          </div>
        );
      })}
    </span>
  );
};

HearingWorksheetLink.propTypes = {
  hearings: PropTypes.array
};
