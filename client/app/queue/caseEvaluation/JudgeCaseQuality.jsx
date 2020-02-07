import React, { useState, useRef, useEffect } from 'react';
import PropTypes from 'prop-types';
import { isEmpty } from 'lodash';

import { marginBottom, marginTop, fullWidth, redText } from '../constants';
import RadioField from '../../components/RadioField';
import CheckboxGroup from '../../components/CheckboxGroup';
import Alert from '../../components/Alert';
import { css } from 'glamor';
import COPY from '../../../COPY';
import JUDGE_CASE_REVIEW_OPTIONS from '../../../constants/JUDGE_CASE_REVIEW_OPTIONS';
import {
  headerStyling,
  errorStylingNoTopMargin,
  hrStyling,
  setWidth,
  fullWidthCheckboxLabels,
  qualityOfWorkAlertStyling,
  subH3Styling,
  qualityIsDeficient
} from './index';

const complexityOpts = Object.entries(JUDGE_CASE_REVIEW_OPTIONS.COMPLEXITY).map(([value, displayText]) => ({
  displayText,
  value
}));

const caseQualityOpts = () => {
  const items = Object.entries(JUDGE_CASE_REVIEW_OPTIONS.QUALITY);

  return items.map(([value, key], idx) => {
    return { value,
      displayText: `${items.length - idx} - ${key}` };
  });
};

const getDisplayOptions = (opts) =>
  Object.entries(JUDGE_CASE_REVIEW_OPTIONS[opts.toUpperCase()]).map(([id, label]) => ({
    id,
    label
  }));

export const JudgeCaseQuality = ({
  highlight = false,
  complexityLabelRef = useRef(null),
  qualityAlertRef = useRef(null),
  qualityLabelRef = useRef(null),
  onChange
}) => {
  const [quality, setQuality] = useState(null);
  const [complexity, setComplexity] = useState(null);
  const [factorsNotConsidered, setFactorsNotConsidered] = useState({});
  const [areasForImprovement, setAreasOfImprovement] = useState({});
  const [postiveFeedback, setPositiveFeedback] = useState({});

  // Notify parent of changes
  useEffect(() => {
    if (onChange) {
      onChange({
        complexity,
        quality,
        factors_not_considered: factorsNotConsidered,
        areas_for_improvement: areasForImprovement,
        positive_feedback: postiveFeedback
      });
    }
  }, [
    quality,
    complexity,
    factorsNotConsidered,
    areasForImprovement,
    postiveFeedback
  ]);

  return (
    <React.Fragment>
      <h2 {...headerStyling} ref={complexityLabelRef}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_SUBHEAD}</h3>
      <RadioField
        vertical
        hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_COMPLEXITY_LABEL}
        onChange={(val) => setComplexity(val)}
        value={complexity}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !complexity ? 'Choose one' : null}
        options={complexityOpts}
      />
      <hr {...hrStyling} />
      <h2 {...headerStyling} ref={qualityLabelRef}>
        {COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
      </h2>
      <h3>{COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_SUBHEAD}</h3>
      <RadioField
        vertical
        hideLabel
        name={COPY.JUDGE_EVALUATE_DECISION_CASE_QUALITY_LABEL}
        onChange={(val) => setQuality(val)}
        value={quality}
        styling={css(marginBottom(0), errorStylingNoTopMargin)}
        errorMessage={highlight && !quality ? 'Choose one' : null}
        options={caseQualityOpts()}
      />
      <div {...css(setWidth('100%'), marginTop(4))}>
        <div className="" {...fullWidth}>
          <h3>{COPY.JUDGE_EVALUATE_DECISION_POSITIVE_FEEDBACK}</h3>
          <CheckboxGroup
            hideLabel
            vertical
            name={COPY.JUDGE_EVALUATE_DECISION_POSITIVE_FEEDBACK}
            onChange={(event) => {
              setPositiveFeedback((prevVals) => ({
                ...prevVals,
                [event.target.getAttribute('id')]: event.target.checked
              }));
            }}
            value={postiveFeedback}
            options={getDisplayOptions('positive_feedback')}
            styling={fullWidthCheckboxLabels}
          />
        </div>
      </div>
      {qualityIsDeficient(quality) && (
        <Alert
          ref={qualityAlertRef}
          type="info"
          scrollOnAlert={false}
          styling={qualityOfWorkAlertStyling}
        >
          Please provide more details about <b>quality of work</b>. If none of
          these apply to this case, please share <b>additional comments</b> below.
        </Alert>
      )}
      <div {...css(setWidth('100%'), marginTop(4))}>
        <h3
          {...css(headerStyling, {
            float: qualityIsDeficient(quality) ? 'left' : ''
          })}
        >
          {COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
        </h3>
        {qualityIsDeficient(quality) && (
          <span {...css(subH3Styling, redText)}>Choose at least one</span>
        )}
      </div>
      <div className="" {...fullWidth}>
        <h4>{COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_NOT_CONSIDERED}</h4>
        <CheckboxGroup
          hideLabel
          vertical
          name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
          onChange={(event) =>
            setFactorsNotConsidered((prevVals) => ({
              ...prevVals,
              [event.target.getAttribute('id')]: event.target.checked
            }))
          }
          value={factorsNotConsidered}
          options={getDisplayOptions('factors_not_considered')}
          styling={fullWidthCheckboxLabels}
        />
      </div>
      <div className="" {...fullWidth}>
        <h4>
          {COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_AREAS_FOR_IMPROVEMENT}
        </h4>
        <CheckboxGroup
          hideLabel
          vertical
          name={COPY.JUDGE_EVALUATE_DECISION_IMPROVEMENT_LABEL}
          onChange={(event) =>
            setAreasOfImprovement((prevVals) => ({
              ...prevVals,
              [event.target.getAttribute('id')]: event.target.checked
            }))
          }
          errorState={
            highlight &&
            qualityIsDeficient(quality) &&
            isEmpty(areasForImprovement)
          }
          options={getDisplayOptions('areas_for_improvement')}
          styling={fullWidthCheckboxLabels}
        />
      </div>
    </React.Fragment>
  );
};

JudgeCaseQuality.propTypes = {
  onChange: PropTypes.func,
  highlight: PropTypes.bool,
  complexityLabelRef: PropTypes.object,
  qualityAlertRef: PropTypes.object,
  qualityLabelRef: PropTypes.object
};
