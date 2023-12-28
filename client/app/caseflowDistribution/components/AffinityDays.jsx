import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import cx from 'classnames';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import COPY from '../../../COPY';
import leverInputValidation from './LeverInputValidation';
import {
  updateAffinityLever
} from '../reducers/Levers/leversActions';

export const AffinityDays = (props) => {
  // set dispatch to redux store
  const dispatch = useDispatch();
  const { leverStore, leverList } = props;

  // place holder to see if store working properly
  const futureLeverList = useSelector((state) => state.caseDistributionLevers.loadedLevers);
  // console.log(`log futureLeverList from hook: ${JSON.stringify(futureLeverList, null, 2)}`);

  const filteredLevers = leverList.map((item) => {
    return leverStore.getState().levers.find((lever) => lever.item === item);
  });

  const checkIfOtherChangesExist = (currentLever) => {

    let leversWithChangesList = [];

    leverStore.getState().levers.map((lever) => {
      if (lever.hasValueChanged === true && lever.item !== currentLever.item) {
        leversWithChangesList.push(lever);
      }
    });

    if (leversWithChangesList.length > 0) {
      return true;
    }

    return false;
  };

  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '15px', left: '100px' },
    '& .usa-input-error label': { bottom: '24px', left: '115px' }
  });
  const errorMessages = {};
  const [affinityLevers, setAffinityLevers] = useState(filteredLevers);
  const [errorMessagesList, setErrorMessages] = useState(errorMessages);

  // package and dispatch lever to redux store
  const dispatchLever = (item, value, hasValueChanged, validChange) => {
    let lever = {
      item,
      value,
      hasValueChanged,
      validChange
    };

    dispatch(updateAffinityLever(lever));
  };

  const updatedLever = (lever, option) => (event) => {
    const levers = affinityLevers.map((individualLever) => {
      if (individualLever.item === lever.item) {
        const updatedOptions = individualLever.options.map((op) => {
          if (op.item === option.item) {

            let initialLever = leverStore.getState().initial_levers.find((original) => original.item === lever.item);

            let validationResponse = leverInputValidation(lever, event, errorMessagesList, initialLever, op);

            const newValue = isNaN(event) ? event : individualLever.value;

            if (validationResponse.statement === 'DUPLICATE') {

              if (checkIfOtherChangesExist(lever)) {
                op.value = event;
                op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
                setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

                // package lever and dispatch to store
                dispatchLever(individualLever.item, newValue, false, true);

                // leverStore.dispatch({
                //   type: ACTIONS.UPDATE_LEVER_VALUE,
                //   updated_lever: { item: individualLever.item, value: newValue },
                //   hasValueChanged: false,
                //   validChange: true

                // });
              } else {
                op.value = event;
                op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
                setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

                // package lever and dispatch to store
                dispatchLever(individualLever.item, newValue, false, false);

                // leverStore.dispatch({
                //   type: ACTIONS.UPDATE_LEVER_VALUE,
                //   updated_lever: { item: individualLever.item, value: newValue },
                //   hasValueChanged: false,
                //   validChange: false

                // });
              }

            }
            if (validationResponse.statement === 'SUCCESS') {
              op.value = event;
              op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
              setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

              // package lever and dispatch to store
              dispatchLever(individualLever.item, newValue, null, true);

              // leverStore.dispatch({
              //   type: ACTIONS.UPDATE_LEVER_VALUE,
              //   updated_lever: { item: individualLever.item, value: newValue },
              //   validChange: true
              // });
            }
            if (validationResponse.statement === 'FAIL') {
              op.value = event;
              op.errorMessage = validationResponse.updatedMessages[`${lever.item}-${option.item}`];
              setErrorMessages(validationResponse.updatedMessages[`${lever.item}-${option.item}`]);

              // package lever and dispatch to store
              dispatchLever(individualLever.item, newValue, null, false);

              // leverStore.dispatch({
              //   type: ACTIONS.UPDATE_LEVER_VALUE,
              //   updated_lever: { item: individualLever.item, value: newValue },
              //   validChange: false
              // });
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

      // package lever and dispatch to store
      // dispatch(dispatchLever(lever.item, option.item, null, true));

      // leverStore.dispatch({
      //   type: ACTIONS.UPDATE_LEVER_VALUE,
      //   updated_lever: { item: lever.item, value: option.item },
      //   validChange: true
      // });
    }
  };
  const generateFields = (dataType, option, lever) => {
    const useAriaLabel = !lever.is_disabled;
    const tabIndex = lever.is_disabled ? -1 : null;

    if (dataType === 'number') {
      return (
        <NumberField
          name={option.item}
          title={option.text}
          label={option.unit}
          isInteger
          readOnly={lever.is_disabled}
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
    if (dataType === 'text') {
      return (
        <TextField
          name={option.item}
          title={option.text}
          label={false}
          readOnly={lever.is_disabled}
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
            <label className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}
              htmlFor={`${lever.item}-${option.item}`}>
              {`${option.text} ${option.data_type === 'number' ? `${option.value} ${option.unit}` : ''}`}
            </label>
          </div>
        </div>
      );
    }

    return null;
  };
  let isMemberUser = !props.isAdmin;

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>Affinity Days</h2>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx(styles.activeLever, lever.is_disabled ? styles.leverDisabled : '')}
          key={`${lever.item}-${index}`}
        >
          <div className={styles.leverLeft}>
            <strong>{lever.title}</strong>
            <p>{lever.description}</p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
            {lever.options.map((option) => (
              (isMemberUser) ?
                generateMemberViewLabel(option, lever) :
                <div key={`${lever.item}-${index}-${option.item}`}>
                  <div>
                    <input
                      checked={option.item === lever.value}
                      type="radio"
                      value={option.item}
                      disabled={lever.is_disabled}
                      id={`${lever.item}-${option.item}`}
                      name={lever.item}
                      onChange={() => handleRadioChange(lever, option)}
                    />
                    <label htmlFor={`${lever.item}-${option.item}`}>
                      {option.text}
                    </label>
                  </div>
                  <div>
                    <div className={styles.combinedRadioInput}>
                      {generateFields(option.data_type, option, lever, isMemberUser)}
                    </div>
                  </div>
                </div>
            ))}
          </div>
        </div>
      ))}
      <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

AffinityDays.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
};
export default AffinityDays;
