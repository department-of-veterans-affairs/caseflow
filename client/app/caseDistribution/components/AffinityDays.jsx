import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import cx from 'classnames';
import NumberField from 'app/components/NumberField';
import TextField from 'app/components/TextField';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import { getUserIsAcdAdmin, getLeversByGroup, getLeverErrors } from '../reducers/levers/leversSelector';
import { Constant } from '../constants';
import { dynamicallyAddAsterisk } from '../utils';
import { validateLever, updateRadioLever } from '../reducers/levers/leversActions';

const AffinityDays = () => {
  const theState = useSelector((state) => state);
  const dispatch = useDispatch();
  const isUserAcdAdmin = getUserIsAcdAdmin(theState);
  const storeLevers = getLeversByGroup(theState, Constant.LEVERS, ACD_LEVERS.lever_groups.affinity);
  const [affinityLevers, setAffinityLevers] = useState(storeLevers);

  const leverErrors = (leverItem) => {
    return getLeverErrors(theState, leverItem);
  };

  useEffect(() => {
    setAffinityLevers(storeLevers);
  }, [storeLevers]);

  const isOptionSelected = (lever, option) => lever.selectedOption === option.item;

  const onChangeRadio = (lever, option) => () => {
    // eslint-disable-next-line camelcase
    const { lever_group, item } = lever;

    dispatch(updateRadioLever(lever_group, item, option.item, option.value));
  };

  const onChangeField = (lever, option) => (event) => {
    // eslint-disable-next-line camelcase
    const { lever_group, item } = lever;

    dispatch(validateLever(lever, item, event, leverErrors(item)));
    dispatch(updateRadioLever(lever_group, item, option.item, event));
  };

  const generateFields = (dataType, option, lever) => {
    const useAriaLabel = !lever.is_disabled_in_ui;
    const tabIndex = lever.is_disabled_in_ui ? -1 : 0;
    const value = lever.valueOptionValue;

    if (dataType === ACD_LEVERS.data_types.number) {
      return (
        <NumberField
          name={option.item}
          title={option.text}
          label={option.unit}
          isInteger
          readOnly={lever.is_disabled_in_ui ? true : !isOptionSelected(lever, option)}
          value={value}
          errorMessage={leverErrors(lever.item)}
          onChange={onChangeField(lever, option)}
          id={`${lever.item}-${value}`}
          inputID={`${lever.item}-${value}-input`}
          useAriaLabel={useAriaLabel}
          tabIndex={tabIndex}
          disabled={lever.is_disabled_in_ui}
        />
      );
    }
    if (dataType === ACD_LEVERS.data_types.text) {
      return (
        <TextField
          name={option.item}
          title={option.text}
          label={false}
          readOnly={lever.is_disabled_in_ui ? true : !isOptionSelected(lever, option)}
          value={value}
          errorMessage={leverErrors(lever.item)}
          onChange={onChangeField(lever, option)}
          id={`${lever.item}-${value}`}
          inputID={`${lever.item}-${value}-input`}
          useAriaLabel={useAriaLabel}
          tabIndex={tabIndex}
          disabled={lever.is_disabled_in_ui}
        />
      );
    }

    return null;
  };

  const generateMemberViewLabel = (option, lever, index) => {
    const affinityLabelId = `affinity-day-label-for-${lever.item}`;

    if (isOptionSelected(lever, option)) {
      return (
        <div key={`${option.item}-${lever.item}-${index}`}>
          <div>
            <label id={affinityLabelId}
              className={lever.is_disabled_in_ui ? 'lever-disabled' : 'lever-active'}
              htmlFor={`${lever.item}-${option.item}`}
            >
              {`${option.text} ${option.data_type === ACD_LEVERS.data_types.number ?
                `${lever.value} ${option.unit}` : ''}`}
            </label>
          </div>
        </div>
      );
    }

    return null;
  };

  const renderAdminInput = (option, lever, index) => {
    const className = cx('combined-radio-input', (isOptionSelected(lever, option)) ? '' : 'outline-radio-input');

    return (
      <div key={`${lever.item}-${index}-${option.item}`}>
        <div className="radio-with-text">
          <input
            checked={isOptionSelected(lever, option)}
            type={ACD_LEVERS.data_types.radio}
            value={option.item}
            disabled={lever.is_disabled_in_ui}
            id={`${lever.item}-${option.item}`}
            name={lever.item}
            onChange={onChangeRadio(lever, option)}
            title={option.text}
          />
          <label htmlFor={`${lever.item}-${option.item}`}>
            <span className="hidden-label-text">{option.text}</span>
          </label>
          <div>{option.text}</div>
        </div>
        <div>
          <div className={className} aria-label={option.unit}>
            {generateFields(option.data_type, option, lever)}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="lever-content">
      <div className="lever-head">
        <h2>{COPY.CASE_DISTRIBUTION_AFFINITY_DAYS_H2_TITLE}</h2>
        <div className="lever-left">
          <strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_LEFT_TITLE}</strong>
        </div>
        <div className="lever-right">
          <strong>{COPY.CASE_DISTRIBUTION_BATCH_SIZE_LEVER_RIGHT_TITLE}</strong>
        </div>
      </div>
      {affinityLevers.map((lever, index) => (
        <div className={cx('active-lever', lever.is_disabled_in_ui ? 'lever-disabled' : '')}
          id={`lever-wrapper-${lever.item}`}
          key={`${lever.item}-${index}`}
        >
          <div className="lever-left">
            <strong>{lever.title}{dynamicallyAddAsterisk(lever)}
            </strong>
            <p className="affinity-lever-text">{lever.description}</p>
          </div>
          <div id={lever.item}
            className={cx('lever-right', 'affinity-lever-num-sec')}
          >
            {lever.options.map((option) => (
              (isUserAcdAdmin) ? renderAdminInput(option, lever, index) : generateMemberViewLabel(option, lever, index)
            ))}
          </div>
        </div>
      ))}
      <h4 className="footer-styling">{COPY.CASE_DISTRIBUTION_FOOTER_ASTERISK_DESCRIPTION}</h4>
      <div className="cf-help-divider"></div>
    </div>
  );
};

export default AffinityDays;
