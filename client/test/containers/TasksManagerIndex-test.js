import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import TasksManagerIndex from '../../app/containers/TasksManagerIndex';
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
  });
});
