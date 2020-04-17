import React, { useContext, useState } from 'react';

import QueueFlowPage from '../../components/QueueFlowPage';
import COPY from '../../../../COPY';
import Button from '../../../components/Button';
import { MotionToVacateContext } from './MotionToVacateContext';
import { adminActionTemplate } from '../../colocatedTasks/AddColocatedTaskView';
import { AddColocatedTaskForm } from '../../colocatedTasks/AddColocatedTaskForm';
import styles from './AddAdminActionsView.module.scss';

export const AddAdminActionsView = () => {
  const [ctx, setCtx] = useContext(MotionToVacateContext);

  const [adminActions, setAdminActions] = useState([adminActionTemplate()]);
  const addItem = () => setAdminActions((prev) => [...prev, adminActionTemplate()]);
  const removeItem = (id) => setAdminActions((prev) => [...prev.filter((item) => item.key !== id)]);
  const updateItem = (value, idx) =>
    setAdminActions((prev) => {
      const updated = [...prev];

      updated[idx] = {
        ...updated[idx],
        ...value
      };

      return updated;
    });

  const onSubmit = () => setCtx({ ...ctx, adminActions });

  return (
    <QueueFlowPage
      //   validateForm={this.validateForm}
      getNextStepUrl={() => ctx.getNextUrl('admin_actions')}
      getPrevStepUrl={() => ctx.getPrevUrl('admin_actions')}
      goToNextStep={() => Boolean(onSubmit())}
    >
      <h1>{COPY.ADD_COLOCATED_TASK_SUBHEAD}</h1>
      <hr />
      <section>
        {adminActions.map((item, idx) => (
          <React.Fragment key={item.key}>
            <AddColocatedTaskForm onChange={(value) => updateItem(value, idx)} value={item} />
            {adminActions.length > 1 && (
              <Button
                willNeverBeLoading
                linkStyling
                className={styles.remove}
                name={COPY.ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL}
                onClick={() => removeItem(item.key)}
              />
            )}
          </React.Fragment>
        ))}
        <div className={styles.controls}>
          <Button
            dangerStyling
            willNeverBeLoading
            name={COPY.ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL}
            onClick={addItem}
          />
        </div>
      </section>
      {/* {error && (
        <Alert title={error.title} type="error">
          {error.detail}
        </Alert>
      )} */}
      {/* {this.actionFormList(adminActions)} */}
    </QueueFlowPage>
  );
};
