---
nav_order: 1
permalink: "index"
nav_exclude: true
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

* [Bat Team Quick Ref](batteam_quick_ref.md)
{% for batteam in site.batteam_items %}
  - <a href="{{ site.baseurl }}{{ batteam.url }}">{{ batteam.title }},
      {{ batteam.name }}, {{ batteam.my_var }}
    </a>
    <br/>tags: {{ batteam.tags | array_to_sentence_string }}
{% endfor %}

## Database
* [Caseflow DB schema](schema/index.html) (created via [Jailer](https://github.com/Wisser/Jailer))
* [Help](help/index.html)
  - [Jekyll](help/jekyll.html)
