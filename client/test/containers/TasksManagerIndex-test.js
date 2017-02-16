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
          toCompleteCount={10}
        />
      );
    };

    it('Does it render', () => {
      renderPage();
      expect(wrapper.text()).to.contain('5 out of 15');
    });
  });
});
