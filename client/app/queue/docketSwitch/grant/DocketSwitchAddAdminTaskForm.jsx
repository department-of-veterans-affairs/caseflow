import React from 'react';
import PropTypes from 'prop-types';

import { Controller, useFormContext } from 'react-hook-form';
import SearchableDropdown from 'app/components/SearchableDropdown';

import colocatedAdminActions from 'constants/CO_LOCATED_ADMIN_ACTIONS';
import StringUtil from 'app/util/StringUtil';
import TextareaField from 'app/components/TextareaField';
import {
  ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL,
  FORM_ERROR_FIELD_REQUIRED,
} from 'app/../COPY';
import { css } from 'glamor';
import Button from 'app/components/Button';

const fieldStyles = css({
  marginTop: '4rem',
});

const actionOptions = Object.entries(colocatedAdminActions).map(
  ([value, label]) => ({ label, value })
);

const { capitalizeFirst, snakeCaseToCamelCase } = StringUtil;

export const DocketSwitchAddAdminTaskForm = ({ baseName, item, onRemove }) => {
  const { control, errors, register } = useFormContext();

  const handleRemove = () => onRemove();

  // We need to submit an actual task name, so reformatting is necessary
  const formatTaskName = (taskStr) =>
    `${capitalizeFirst(snakeCaseToCamelCase(taskStr))}ColocatedTask`;

  return (
    <>
      <div className={fieldStyles}>
        <Controller
          name={`${baseName}.type`}
          control={control}
          defaultValue={item.type}
          render={({ onChange, ...rest }) => (
            <SearchableDropdown
              {...rest}
              label="Select the type of task you'd like to open:"
              options={actionOptions}
              onChange={(valObj) => onChange(formatTaskName(valObj?.value))}
            />
          )}
        />
      </div>

      <div className={fieldStyles}>
        <TextareaField
          errorMessage={
            errors?.[baseName]?.instructions ? FORM_ERROR_FIELD_REQUIRED : null
          }
          name={`${baseName}.instructions`}
          defaultValue={item.instructions}
          label={ADD_COLOCATED_TASK_INSTRUCTIONS_LABEL}
          inputRef={register()}
        />
      </div>
      <div>
        <Button linkStyling onClick={handleRemove}>
          Remove this action
        </Button>
      </div>
    </>
  );
};

DocketSwitchAddAdminTaskForm.propTypes = {
  baseName: PropTypes.string.isRequired,
  item: PropTypes.shape({
    type: PropTypes.shape({ value: PropTypes.string, label: PropTypes.string }),
    instructions: PropTypes.string,
  }),
  onRemove: PropTypes.func.isRequired,
};
