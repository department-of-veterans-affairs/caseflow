import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TasksManagerIndex from '../../app/containers/TasksManager/TasksManagerIndex';
import { createTask } from '../factory';


describe('TasksManagerIndex', () => {
  context('.render', () => {
    let wrapper;
    let tasks;
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
    };

    beforeEach(() => {
      tasks = createTask(5);
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
