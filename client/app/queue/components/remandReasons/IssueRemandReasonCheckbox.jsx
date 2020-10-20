import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Checkbox from '../../../components/Checkbox';
import RadioField from '../../../components/RadioField';

import COPY from '../../../../COPY';
import { css } from 'glamor';
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
    onChange?.({ id: option.id, values: state });
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
