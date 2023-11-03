import React from 'react';
import PropTypes from 'prop-types';
import Checkbox from 'app/components/Checkbox';

const CHECKBOX_OPTIONS = [
  {
    label: 'Higher-Level Reviews',
    name: 'HigherLevelReview'
  },
  {
    label: 'Supplemental Claims',
    name: 'SupplementalClaim'
  }
];

export const DecisionReviewType = ({ field, name, register }) => {
  return (
    <div className="decisionReviewTypeContainer">
      {CHECKBOX_OPTIONS.map((checkbox) => (
        <Checkbox
          defaultValue={field.reviewType?.[checkbox.name]}
          key={`checkbox-${checkbox.name}`}
          inputRef={register}
          label={checkbox.label}
          name={`${name}.reviewType.${checkbox.name}`}
          unpadded
        />
      ))}
    </div>
  );
};

DecisionReviewType.propTypes = {
  field: PropTypes.object,
  name: PropTypes.string,
  register: PropTypes.func
};
