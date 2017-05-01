import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TasksManagerIndex from '../../../app/containers/TasksManager/TasksManagerIndex';


describe('TasksManagerIndex', () => {
  context('.render', () => {
    let wrapper;

    let renderPage = () => {
      const quotas = [{
        user_name: 'Billy Bob Thorton',
        task_count: 3,
        completed_tasks_count: 1,
        tasks_left_count: 2
      }];

      wrapper = shallow(
        <TasksManagerIndex
          completedCountToday={5}
          employeeCount="3"
          toCompleteCount={10}
          userQuotas={quotas}
        />
      );
    };

    it('Does it render', () => {
      renderPage();
      expect(wrapper.text()).to.contain('5 out of 15');
    });
  });
});
