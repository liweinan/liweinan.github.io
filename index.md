<ul>
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url }}">{{ post.title }}</a>
      <p>      
      {{ post.abstract }}
      </p>
    </li>
  {% endfor %}
</ul>
