---
nav_order: 0
has_children: true
permalink: "index"
---

# Contents

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

{% assign doclist = site.html_pages | where_exp:"item", "item.title != nil" | where_exp:"item", "item.nav_order != nil" | sort: 'nav_order'  %}
<ol>
{% for item in doclist %}
    <li><a href="{{ site.url }}{{ site.baseurl }}{{ item.url }}">{{ item.title }}</a></li>
{% endfor %}
</ol>


## Bat Team Items (Jekyll collection test)
{% for batteam in site.batteam_items %}
  - <a href="{{ site.baseurl }}{{ batteam.url }}">{{ batteam.title }},
      {{ batteam.name }}, {{ batteam.my_var }}
    </a>
    <br/>tags: {{ batteam.tags | array_to_sentence_string }}
{% endfor %}

## Database
* [Caseflow DB schema](schema/db_schema)
  - [Table associations](schema/html/) (created via [Jailer](https://github.com/Wisser/Jailer))
* [Task trees](task_trees/index.html)
* [Help subsite](help/index.html)
  - [Diagram examples](help/diagrams)
  - [Jekyll](help/jekyll)
