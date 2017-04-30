<ul>{% for post in site.posts %}<li><a href="{{ post.url }}">{{ post.title }}</a>. {{ post.date | date: '%B %d, %Y' }}.<p>{{ post.abstract }}</p></li>{% endfor %}</ul>
