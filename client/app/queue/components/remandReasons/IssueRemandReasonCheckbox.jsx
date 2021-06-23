import React, { useEffect, useRef, useState } from 'react';
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
  prefix = '',
  value: valueProp,
}) => {
  const [state, setState] = useState({ value: false, post_aoj: null });
  const firstUpdate = useRef(true);
  const copyPrefix = isLegacyAppeal ? 'LEGACY' : 'AMA';

  const handleCheckboxChange = (value) => setState({ value, post_aoj: null });
  const handleRadioChange = (val) => setState({ ...state, post_aoj: val });

  useEffect(() => {
    // No need to hit callback until something changes
    if (firstUpdate.current) {
      firstUpdate.current = false;

      return;
    }

    onChange?.({
      code: option.id,
      checked: state.value,
      post_aoj: state.post_aoj,
    });
  }, [state.value, state.post_aoj]);

  useEffect(() => {
    if (valueProp) {
      setState({
        value: valueProp.checked ?? true,
        // eslint-disable-next-line camelcase
        post_aoj: valueProp?.post_aoj?.toString() ?? null,
      });
    }
  }, [valueProp]);

  const prefixedId = `${prefix}-${option.id}`;

  return (
    <React.Fragment key={prefixedId}>
      <Checkbox
        name={prefixedId}
        onChange={handleCheckboxChange}
        value={state.value}
        label={option.label}
        unpadded
      />
      {state.value && (
        <RadioField
          // eslint-disable-next-line no-undefined
          errorMessage={(highlight && state.post_aoj === null) ? 'Choose one' : undefined}
          styling={css(smallLeftMargin, smallBottomMargin, errorNoTopMargin)}
          name={`${prefixedId}-postAoj`}
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
          value={String(state.post_aoj)}
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
  prefix: PropTypes.string,
  value: PropTypes.shape({
    code: PropTypes.string.isRequired,
    checked: PropTypes.bool.isRequired,
    post_aoj: PropTypes.bool.isRequired,
  }),
};
