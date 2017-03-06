<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <p>&nbsp;</p>
      {{ post.excerpt }}
    </li>
  {% endfor %}
</ul>
