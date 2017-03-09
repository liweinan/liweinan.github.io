<ul>{% for post in site.posts %}<li><a href="{{ post.url }}">{{ post.title }}</a> _{{ post.date | date: '%B %d, %Y' }}_<p>{{ post.abstract }}</p></li>{% endfor %}</ul>
