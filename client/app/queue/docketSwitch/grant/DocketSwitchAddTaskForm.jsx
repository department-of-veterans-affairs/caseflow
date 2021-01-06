import React, { useMemo, useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { useForm, Controller } from 'react-hook-form';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { CheckoutButtons } from './CheckoutButtons';
import {
  DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL,
  DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS,
  DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT,
  DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { yupResolver } from '@hookform/resolvers';
import * as yup from 'yup';
import { css } from 'glamor';
import ReactMarkdown from 'react-markdown';
import CheckboxGroup from 'app/components/CheckboxGroup';
import colocatedAdminActions from '../../../../constants/CO_LOCATED_ADMIN_ACTIONS';
import Button from '../../../components/Button';

const schema = yup.object().shape({
  taskIds: yup.string().required()
});

export const DocketSwitchAddTaskForm = ({
  onSubmit,  
  onCancel,
  docketName
  }) => {
  const { register, handleSubmit, control, formState, watch } = useForm({
    resolver: yupResolver(schema),
    mode: 'onChange',
  });
  
const [tasks, setTasks] = useState({});

const sectionStyle = css({ marginBottom: '24px' });


const actionOptions = useMemo(() => {
    return Object.entries(colocatedAdminActions).map(([value, label]) => 
      ({ label: `${label} task`,
         value: true})) 
  }, [colocatedAdminActions]);

 const selectedIssues = useMemo(() => {
    return Object.entries(actionOptions).filter((item) => item[1]).
      flatMap((item) => item[0]);
  }, [actionOptions]);

 const selectAllIssues = () => {
    const checked = selectedIssues.length === 0;
    const newValues = {};

     actionOptions.forEach((item) => newValues[item.label] = checked);
     console.log("checked", actionOptions.map((item) => newValues[item.label] = checked));
    // setTasks(newValues);
  };

  // populate all of our checkboxes on initial render
  useEffect(() => selectAllIssues(), []);

 const onIssueChange = (evt) => {
    setTasks({ ...tasks, [evt.target.name]: evt.target.checked });
  };

  console.log("tasking", actionOptions);

 
  return (
    <form
      className="docket-switch-granted-add"
      onSubmit={handleSubmit(onSubmit)}
      aria-label="Grant Docket Switch Add Task"
     >
      <AppSegment filledBackground>
        <h1>{DOCKET_SWITCH_GRANTED_ADD_TASK_LABEL}</h1>
        <div {...sectionStyle}>
        <ReactMarkdown source={sprintf(DOCKET_SWITCH_GRANTED_ADD_TASK_INSTRUCTIONS, _.startCase(_.toLower(docketName)))}/>
        </div>
        <div><ReactMarkdown source={DOCKET_SWITCH_GRANTED_ADD_TASK_TEXT}/></div>
        <Controller
          name="taskIds"
          control={control}
          defaultValue={[]}
          render={({ onChange: onCheckChange }) => {
          return (
        <CheckboxGroup
          name="issues"
          label="Please unselect any tasks you would like to remove:"
          strongLabel
          options={actionOptions}
          onChange={(event) => onCheckChange(onIssueChange(event))}
          styling={css({ marginBottom: '0' })}
          // checked={tasks}
          // values={tasks} 
        />
         );
        }}
        />
       
        <React.Fragment>
        <h3 {...css({marginBottom: '0'})}>
          <br />
          <strong>Would you like to add any additional tasks?
          </strong><br /></h3>
          <Button
            willNeverBeLoading
            dangerStyling
            styling={css({ marginTop: '1rem' })}
            name={DOCKET_SWITCH_GRANTED_ADD_TASK_BUTTON}
          />
      </React.Fragment>
      </AppSegment>
      <div className="controls cf-app-segment">
      <CheckoutButtons
        disabled={!formState.isValid}
        onCancel={onCancel}
        onSubmit={handleSubmit(onSubmit)}
      />
     </div>
    </form>
  );
};
DocketSwitchAddTaskForm.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  docketName: PropTypes.string  
};