import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TasksManagerIndex from '../../app/containers/TasksManager/TasksManagerIndex';


describe('TasksManagerIndex', () => {
  context('.render', () => {
    let wrapper;

    let renderPage = () => {
      wrapper = shallow(
        <TasksManagerIndex
          completedCountToday={5}
          employeeCount={3}
          toCompleteCount={10}
          tasksCompletedByUsers={{user: 10}}
        />
      );
    };

    it('Does it render', () => {
      renderPage();
      expect(wrapper.text()).to.contain('5 out of 15');
    });
  });
});
