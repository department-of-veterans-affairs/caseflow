import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes, { object } from 'prop-types';
import { ACTIONS } from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import { css } from 'glamor';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import NumberField from 'app/components/NumberField';
import leverInputValidation from './LeverInputValidation';
import COPY from '../../../COPY';
import { checkIfOtherChangesExist } from '../utils.js';

const BatchSize = (props) => {
  const leverNumberDiv = css({
    '& .cf-form-int-input': { width: 'auto', display: 'inline-block', position: 'relative' },
    '& .cf-form-int-input .input-container': { width: 'auto', display: 'inline-block', verticalAlign: 'middle' },
    '& .cf-form-int-input label': { position: 'absolute', bottom: '8px', left: '75px' },
    '& .usa-input-error label': { bottom: '15px', left: '89px' }
  });
  const isMemberUser = !props.isAdmin;
  const { leverList, leverStore, loadedLevers } = props;
  const [errorMessagesList, setErrorMessages] = useState({});
  const [batchSizeLevers, setBatchSizeLevers] = useState(useSelector((state) => state.caseDistributionLevers.loadedLevers.batch));

  const updateLever = (index) => (event) => {
    const levers = batchSizeLevers.map((lever, i) => {
      if (index === i) {

        // let initialLever = leverStore.getState().initial_levers.find((original) => original.item === lever.item);

        let validationResponse = leverInputValidation(lever, event, errorMessagesList, lever);

        if (validationResponse.statement === 'DUPLICATE') {

          if (checkIfOtherChangesExist(lever)) {
            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);

            leverStore.dispatch({
              type: ACTIONS.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              hasValueChanged: false,
              validChange: true
            });
          } else {

            lever.value = event;
            setErrorMessages(validationResponse.updatedMessages);

            leverStore.dispatch({
              type: ACTIONS.UPDATE_LEVER_VALUE,
              updated_lever: { item: lever.item, value: event },
              hasValueChanged: false,
              validChange: false
            });
          }

        }
        if (validationResponse.statement === 'SUCCESS') {

          lever.value = event;
          setErrorMessages(validationResponse.updatedMessages);
          leverStore.dispatch({
            type: ACTIONS.UPDATE_LEVER_VALUE,
            updated_lever: { item: lever.item, value: event },
            validChange: true
          });

          return lever;
        }
        if (validationResponse.statement === 'FAIL') {
          lever.value = event;
          setErrorMessages(validationResponse.updatedMessages);

          leverStore.dispatch({
            type: ACTIONS.UPDATE_LEVER_VALUE,
            updated_lever: { item: lever.item, value: event },
            validChange: false
          });

          return lever;
        }
      }

      return lever;
    });

    setBatchSizeLevers(levers);
  };

  return (
    <div className={styles.leverContent}>
      <div className={styles.leverHead}>
        <h2>Batch Size</h2>
        <div className={styles.leverLeft}><strong>Data Elements</strong></div>
        <div className={styles.leverRight}><strong>Value</strong></div>
      </div>
      {batchSizeLevers && batchSizeLevers.map((lever, index) => (
        <div className={styles.activeLever} key={`${lever.item}-${index}`}>
          <div className={styles.leverLeft}>
            <strong className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>{lever.title}</strong>
            <p className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>{lever.description}</p>
          </div>
          <div className={`${styles.leverRight} ${leverNumberDiv}`}>
            {isMemberUser ?

              <label className={lever.is_disabled ? styles.leverDisabled : styles.leverActive}>
                {lever.value} {lever.unit}
              </label> :
              <NumberField
                name={lever.item}
                label={lever.unit}
                isInteger
                readOnly={lever.is_disabled}
                value={lever.value}
                errorMessage={errorMessagesList[lever.item]}
                onChange={updateLever(index, lever.item, lever.item)}
                tabIndex={lever.is_disabled ? -1 : null}
              />
            }
          </div>
        </div>
      ))}
      <h4 className={styles.footerStyling}>{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

BatchSize.propTypes = {
  leverList: PropTypes.arrayOf(PropTypes.string).isRequired,
  leverStore: PropTypes.any,
  isAdmin: PropTypes.bool.isRequired,
  loadedLevers: PropTypes.arrayOf(object).isRequired
};

export default BatchSize;
