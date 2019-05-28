import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import SearchableDropdown from '../components/SearchableDropdown';
import { css } from 'glamor';

const tableStyling = css({
  width: '100%',
  '& td': { border: 'none' },
  '& input': { margin: 0 }
});

const ACTION_SETS = [
  {
    conditions: ['parent_is_a_judge_task', 'parent_assigned_to_me'],
    actions: ['Assign to attorney']
  },
  {
    conditions: ['assigned_to_me', 'on_timed_hold'],
    actions: ['Decision ready for review', 'Add admin action', 'End hold early']
  },
  {
    conditions: ['assigned_to_me'],
    actions: ['Decision ready for review', 'Add admin action', 'Put task on hold']
  },
  {
    conditions: ['NONE'],
    actions: ['NONE']
  }
];

class TaskActionsConfigurator extends React.PureComponent {
  render = () => <AppSegment filledBackground>
    <div>
      <h1>Task Actions Configuration</h1>
      <table {...tableStyling}>
        <tbody>
          <TaskClassHeader>Attorney Task</TaskClassHeader>
          <ActionSetList actionSets={ACTION_SETS} />
        </tbody>
      </table>

    </div>
  </AppSegment>;
}

export default TaskActionsConfigurator;

const sectionHeadingStyling = css({
  fontSize: '3rem',
  fontWeight: 'bold'
});

class TaskClassHeader extends React.PureComponent {
  render = () => {
    return <tr><td {...sectionHeadingStyling} colSpan="7">{this.props.children}</td></tr>;
  }
}

const labelRowStyling = css({
  '& td': { fontWeight: 'bold' }
});

class ActionSetList extends React.PureComponent {
  render = () => {
    return <React.Fragment>
      <tr {...labelRowStyling}>
        <td>Conditions</td>
        <td>Actions</td>
      </tr>
      { this.props.actionSets.map((actionSet) => <ActionSet {...actionSet} />) }
    </React.Fragment>;
  }
}

class ActionSet extends React.PureComponent {
  conditions = () => this.props.conditions.map((condition) => ({
    value: condition,
    label: condition,
    tagId: condition
  }));

  actions = () => this.props.actions.map((action) => ({
    value: action,
    label: action,
    tagId: action
  }));

  // name="feature_toggles"
  // label="Remove or add new feature toggles"
  // multi
  // creatable
  // options={featureOptions}
  // placeholder=""
  // value={featureOptions}
  // selfManageValueState
  // onChange={this.featureToggleOnChange}
  // creatableOptions={{ promptTextCreator: (tagName) => `Enable feature toggle "${_.trim(tagName)}"` }}

  render = () => {
    // debugger;

    return <tr>
      <td>
        <SearchableDropdown
          multi
          name="Conditions"
          hideLabel
          value={this.conditions()}
        />
      </td>
      <td>
        <SearchableDropdown
          multi
          name="Actions"
          hideLabel
          value={this.actions()}
        />
      </td>
    </tr>;
  }
}
