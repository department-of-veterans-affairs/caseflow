export let createTask = (count = 1, values = {}) => {
  let tasks = [];
  for (var  i = 0; i < count; i++) {
    let task = {
      type: values.type || 'EstablishClaim',
      user: values.user || createUser(1),
      appeal: values.appeal || createAppeal(1)
    }
    tasks.push(task);
  }

  return tasks.length === 1 ? tasks[0] : tasks;
}

export let createUser = (count = 1, values = {}) => {
  let users = [];
  for (var  i = 0; i < count; i++) {
    let user = {
      id: (values.startingId || 1) + i,
      css_id: values.css_id || `123-${i}`,
      station_id: '456'
    };
    users.push(user);
  }

  return users.length === 1 ? users[0] : users;
}

export let createAppeal = (count = 1, values = {}) => {
  let appeals = [];
  for (var  i = 0; i < count; i++) {
    let appeal = {
      id: (values.startingId || 1) + 1,
      vacols_id: `123-${i}`,
      vbms_id: `456-${i}`
    };
    appeals.push(appeal);
  }

  return appeals.length === 1 ? appeals[0] : appeals;
}
