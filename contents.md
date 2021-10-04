---
nav_order: 0
permalink: "index"
---

Caseflow has documentation in various locations depending on its purpose and visibility.

| Repository | GitHub Wiki | GitHub Pages |
|----------------|------|-------|
| `caseflow` (public) | [Wiki](https://github.com/department-of-veterans-affairs/caseflow/wiki) | [Pages (this site)](https://department-of-veterans-affairs.github.io/caseflow/) -- see Contents below |
| `appeals-deployment` (*private*) | [Wiki](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki) | [Pages](https://verbose-broccoli-9868be41.pages.github.io/) has [Bat Team Quick Ref](https://verbose-broccoli-9868be41.pages.github.io/batteam-quickref.html) |
| [`appeals-team`](https://github.com/department-of-veterans-affairs/appeals-team) (*private*) | [Wiki](https://github.com/department-of-veterans-affairs/appeals-team/wiki) | N/A |
| [`appeals-training`](https://github.com/department-of-veterans-affairs/appeals-training) (*private*) | N/A | N/A |
| [`appeals-support`](https://github.com/department-of-veterans-affairs/appeals-support) (*private*) (old) | N/A | N/A |

GitHub Pages offers [more documentation presentation features](README.md#why-not-use-the-github-wiki) than GitHub Wiki.

# Contents

## Database
* [Caseflow DB schema](schema/db_schema): with diagrams and relevant tables for each Caseflow product
* [Table associations subsite](schema/html/) (created via [Jailer](https://github.com/Wisser/Jailer)): provides SQL joins clauses for basic and polymorphic associations
* [Task trees subsite](task_trees/index.html): roles, tasks, and statistics from real task trees

## Help and examples
* [README](README.html)
* [Help subsite](help/index.html)
  - [Diagram examples](help/diagrams)
  - [Jekyll](help/jekyll)


## For fun

<p>
  <button class="btn js-toggle-dark-mode">Preview dark theme</button>
  <script>
    const toggleDarkMode = document.querySelector('.js-toggle-dark-mode');
    jtd.addEvent(toggleDarkMode, 'click', function() {
      if (jtd.getTheme() === 'dark') {
        jtd.setTheme('light');
        toggleDarkMode.textContent = 'Preview dark theme';
      } else {
        jtd.setTheme('dark');
        toggleDarkMode.textContent = 'Return to the light side';
      }
    });
  </script>
</p>

