import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

import Checkbox from 'app/components/Checkbox';
import RadioField from 'app/components/RadioField';
import COPY from 'app/../COPY';
import {
  errorNoTopMargin,
  smallBottomMargin,
  smallLeftMargin,
} from './constants';

export const IssueRemandReasonCheckbox = ({
  isLegacyAppeal = false,
  highlight = false,
  option = {},
  onChange,
}) => {
  const [state, setState] = useState({ value: false, post_aoj: null });
  const copyPrefix = isLegacyAppeal ? 'LEGACY' : 'AMA';

  const handleCheckboxChange = (value) => setState({ value, post_aoj: null });
  const handleRadioChange = (val) => setState({ ...state, post_aoj: val });

  useEffect(() => {
    onChange?.({ code: option.id, checked: state.value, post_aoj: state.post_aoj });
  }, [state.value, state.post_aoj]);

  return (
    <React.Fragment key={option.id}>
      <Checkbox
        name={option.id}
        onChange={handleCheckboxChange}
        value={state.value}
        label={option.label}
        unpadded
      />
      {state.value && (
        <RadioField
          errorMessage={highlight && state.post_aoj === null && 'Choose one'}
          styling={css(smallLeftMargin, smallBottomMargin, errorNoTopMargin)}
          name={`${option.id}-postAoj`}
          vertical
          hideLabel
          options={[
            {
              displayText:
                COPY[`${copyPrefix}_REMAND_REASON_POST_AOJ_LABEL_BEFORE`],
              value: 'false',
            },
            {
              displayText:
                COPY[`${copyPrefix}_REMAND_REASON_POST_AOJ_LABEL_AFTER`],
              value: 'true',
            },
          ]}
          value={state.post_aoj}
          onChange={handleRadioChange}
        />
      )}
    </React.Fragment>
  );
};
IssueRemandReasonCheckbox.propTypes = {
  isLegacyAppeal: PropTypes.bool,
  highlight: PropTypes.bool,
  option: PropTypes.shape({
    id: PropTypes.string,
    label: PropTypes.oneOfType([PropTypes.string, PropTypes.node]),
  }),
  onChange: PropTypes.func,
};
