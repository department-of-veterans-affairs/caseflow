import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import cx from 'classnames';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { ACTIONS } from '../reducers/levers/leversActionTypes';
import leverInputValidation from './LeverInputValidation';
import { checkIfOtherChangesExist } from '../utils';

const AffinityDays = (props) => {
  const { leverStore, isAdmin } = props;

  const errorMessages = {};

  const [errorMessagesList, setErrorMessages] = useState(errorMessages);
  const storeLevers = useSelector((state) => state.caseDistributionLevers.levers.affinity);
  const backendLevers = useSelector((state) => state.caseDistributionLevers.backendLevers.affinity);
  const [affinityLevers, setAffinityLevers] = useState(storeLevers);

  useEffect(() => {
    setAffinityLevers(storeLevers);
  }, [storeLevers]);

  const updatedLever = (lever, option) => (event) => {
    const levers = affinityLevers.map((individualLever) => {
      if (individualLever.item === lever.item) {
        const updatedOptions = individualLever.options.map((op) => {
          if (op.item === option.item) {

            let initialLever = backendLevers.find((original) => original.item === lever.item);

            let validationResponse = leverInputValidation(lever, event, errorMessagesList, initialLever, op);

            const newValue = isNaN(event) ? event : individualLever.value;

            if (validationResponse.statement === ACD_LEVERS.DUPLICATE) {

              if (checkIfOtherChangesExist(lever)) {
                op.value = event;
                op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
                setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

                leverStore.dispatch({
                  type: ACTIONS.UPDATE_LEVER_VALUE,
                  updated_lever: { item: individualLever.item, value: newValue },
                  hasValueChanged: false,
                  validChange: true

                });
              } else {
                op.value = event;
                op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
                setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

                leverStore.dispatch({
                  type: ACTIONS.UPDATE_LEVER_VALUE,
                  updated_lever: { item: individualLever.item, value: newValue },
                  hasValueChanged: false,
                  validChange: false

                });
              }

            }
            if (validationResponse.statement === ACD_LEVERS.SUCCESS) {
              op.value = event;
              op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
              setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);
              leverStore.dispatch({
                type: ACTIONS.UPDATE_LEVER_VALUE,
                updated_lever: { item: individualLever.item, value: newValue },
                validChange: true
              });
            }
            if (validationResponse.statement === ACD_LEVERS.FAIL) {
              op.value = event;
              op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
              setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);
              leverStore.dispatch({
                type: ACTIONS.UPDATE_LEVER_VALUE,
                updated_lever: { item: individualLever.item, value: newValue },
                validChange: false
              });
            }
          }

          return op;
        });

        return { ...individualLever, options: updatedOptions };
      }

      return individualLever;
    });

    setAffinityLevers(levers);

  };

  const handleRadioChange = (lever, option) => {
    if (lever && option) {
      const updatedLevers = affinityLevers.map((lev) => {
        if (lev.item === lever.item) {
          return { ...lev, value: option.item };
        }

        return lev;
      });

      setAffinityLevers(updatedLevers);
      leverStore.dispatch({
        type: ACTIONS.UPDATE_LEVER_VALUE,
        updated_lever: { item: lever.item, value: option.item },
        validChange: true
      });
    }
  };

  const generateFields = (dataType, option, lever) => {
    const useAriaLabel = !lever.is_disabled_in_ui;
    const tabIndex = lever.is_disabled_in_ui ? -1 : null;

    if (dataType === ACD_LEVERS.number) {
      return (
        <NumberField
          name={option.item}
          title={option.text}
          label={option.unit}
          isInteger
          readOnly={lever.is_disabled_in_ui ? true : (lever.value !== option.item)}
          value={option.value}
          errorMessage={option.errorMessage}
          onChange={(event) => updatedLever(lever, option)(event)}
          id={`${lever.item}-${option.value}`}
          inputID={`${lever.item}-${option.value}-input`}
          useAriaLabel={useAriaLabel}
          tabIndex={tabIndex}
        />
      );
    }
    if (dataType === ACD_LEVERS.text) {
      return (
        <TextField
          name={option.item}
          title={option.text}
          label={false}
          readOnly={lever.is_disabled_in_ui ? true : (lever.value !== option.item)}
          value={option.value}
          onChange={(event) => updatedLever(lever, option)(event)}
          id={`${lever.item}-${option.value}`}
          inputID={`${lever.item}-${option.value}-input`}
          useAriaLabel={useAriaLabel}
          tabIndex={tabIndex}
        />
      );
    }

    return null;
  };

  const generateMemberViewLabel = (option, lever) => {
    if (lever.value === option.item) {
      return (
        <div>
          <div>
            <label className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}
              htmlFor={`${lever.item}-${option.item}`}>
              {`${option.text} ${option.data_type === ACD_LEVERS.number ? `${option.value} ${option.unit}` : ''}`}
            </label>
          </div>
        </div>
      );
    }

    return null;
  };

  const renderAdminInput = (option, lever, index) => {
    const className = cx('combined-radio-input', (lever.value === option.item) ? '' : 'outline-radio-input');

    return (
      <div key={`${lever.item}-${index}-${option.item}`}>
        <div>
          <input
            checked={option.item === lever.value}
            type={ACD_LEVERS.radio}
            value={option.item}
            disabled={lever.is_disabled_in_ui}
            id={`${lever.item}-${option.item}`}
            name={lever.item}
            onChange={() => handleRadioChange(lever, option)}
          />
          <label htmlFor={`${lever.item}-${option.item}`}>
            {option.text}
          </label>
        </div>
        <div>
          <div className={className}>
            {generateFields(option.data_type, option, lever, isAdmin)}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className='lever-content'>
      <div className='lever-head'>
        <h2>{COPY.CASE_DISTRIBUTION_AFFINITY_DAYS_H2_TITLE}</h2>
        <div className='lever-left'>
          <strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_LEFT_TITLE}</strong>
        </div>
        <div className='lever-right'>
          <strong>{COPY.CASE_DISTRIBUTION_BATCHSIZE_LEVER_RIGHT_TITLE}</strong>
        </div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx('active-lever', lever.is_disabled_in_ui ? 'lever-disabled' : '')}
          key={`${lever.item}-${index}`}
        >
          <div className='lever-left'>
            <strong>{lever.title}</strong>
            <p>{lever.description}</p>
          </div>
          <div className={`lever-right affinity-lever-num-sec`}>
            {lever.options.map((option) => (
              (isAdmin) ? renderAdminInput(option, lever, index) : generateMemberViewLabel(option, lever)
            ))}
          </div>
        </div>
      ))}
      <h4 className='footer-styling'>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className='cf-help-divider'></div>
    </div>
  );
};

AffinityDays.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
};
export default AffinityDays;
