import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import moment from 'moment';

import { COLORS } from '../../constants/AppConstants';

import TextareaField from '../../components/TextareaField';

export const UnscheduledNotes = ({
  updatedByCssId,
  updatedAt,
  onChange,
  uniqueId,
  unscheduledNotes
}) => {
  return (
    <React.Fragment>
      <TextareaField
        maxlength={1000}
        label="Notes"
        name={`${uniqueId}-unscheduled-notes`}
        strongLabel
        onChange={(notes) => onChange(notes)}
        labelStyling={css({ float: 'left' })}
        styling={css({ marginBottom: 1 })}
        value={unscheduledNotes ?? ''}
        characterLimitTopRight
      />
      {updatedByCssId && updatedAt && unscheduledNotes &&
        <span style={{ color: COLORS.GREY }}>
          {`Last updated by ${updatedByCssId} on ${moment(updatedAt).format('MM/DD/YYYY')}`}
        </span>
      }
    </React.Fragment>
  );
};

UnscheduledNotes.propTypes = {
  updatedByCssId: PropTypes.string,
  updatedAt: PropTypes.string,
  unscheduledNotes: PropTypes.string,
  onChange: PropTypes.func,
  uniqueId: PropTypes.number
};
