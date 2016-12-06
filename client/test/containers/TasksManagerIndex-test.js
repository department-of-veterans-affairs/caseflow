import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TasksManagerIndex from '../../app/containers/TasksManagerIndex';



describe.only('TasksManagerIndex', () => {
  context('.render', () => {
    let wrapper;
    let tasks;
    let completedTasks;
    let completedCountTotal;

    let renderPage = () => {
      wrapper = shallow(
        <TasksManagerIndex
          completedCountToday={5}
          completedCountTotal={completedCountTotal}
          completedTasks={tasks}
          toCompleteCount={10}
          toCompleteTasks={[]}
        />
      );
    }

    beforeEach(() => {
      tasks = [1,2,3,4,5].map(i => (
        { user: 'a', appeal: 'b' }
      ));
    });

    context('See more link', () => {
      it('shows when more available completed tasks', () => {
        completedCountTotal = 10;
        renderPage();
        expect(wrapper.find('#fetchCompletedTasks')).to.have.length(1);
      });

      it('hides when already have all completed tasks', () => {
        completedCountTotal = 3;
        renderPage();
        expect(wrapper.find('#fetchCompletedTasks')).to.have.length(0);
      });
    });
  });
});
