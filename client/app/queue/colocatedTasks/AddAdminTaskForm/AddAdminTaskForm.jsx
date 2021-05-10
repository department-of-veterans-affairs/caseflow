import React, { useEffect, useMemo, useRef } from 'react';
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

const { capitalizeFirst, snakeCaseToCamelCase, camelCaseToSnakeCase } = StringUtil;

export const AddAdminTaskForm = ({ baseName, item, onRemove }) => {
  const { control, errors, register } = useFormContext();
  const selectRef = useRef();

  const handleRemove = () => onRemove();

  // We need to submit an actual task name, so reformatting is necessary
  const formatTaskName = (taskStr) =>
    `${capitalizeFirst(snakeCaseToCamelCase(taskStr))}ColocatedTask`;

  // Ensure we focus the SearchableDropdown when component is mounted (and ref is hooked up)
  useEffect(() => {
    selectRef?.current?.focus();
  }, [selectRef.current]);

  // Used for populating the SearchableDropdown if a value already exists (likely via defaultValues on the parent form)
  const defaultVal = useMemo(() => {
    if (!item?.type) {
      return;
    }

    const value = camelCaseToSnakeCase(item.type).replace(/^_|_colocated_task/g, '');

    return actionOptions.find((opt) => opt.value === value);
  });

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
              inputRef={(ref) => {
                selectRef.current = ref;
              }}
              defaultValue={defaultVal}
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

AddAdminTaskForm.propTypes = {
  baseName: PropTypes.string.isRequired,
  item: PropTypes.shape({
    type: PropTypes.shape({ value: PropTypes.string, label: PropTypes.string }),
    instructions: PropTypes.string,
  }),
  onRemove: PropTypes.func.isRequired,
};
